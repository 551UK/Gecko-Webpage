#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// Detect the native Reynard 0.19.0 error view while the app is running.
// This is intentionally restricted to Unknown Protocol, not normal HTTP,
// SSL, offline, or certificate errors.
extern void CGKioskRecoverHome(UIViewController *controller);

static IMP CGOriginalErrorSetHidden = NULL;
static char CGUnknownProtocolHandledKey;
static BOOL CGRuntimeHookInstalled = NO;

static BOOL CGHasUnknownProtocolTitle(UIView *view) {
    NSString *localized = [[NSBundle mainBundle]
        localizedStringForKey:@"Unknown Protocol"
                       value:@"Unknown Protocol"
                       table:@"WebContentErrorLocalizable"];
    NSMutableArray<UIView *> *queue = [NSMutableArray arrayWithObject:view];
    while (queue.count) {
        UIView *next = queue.lastObject;
        [queue removeLastObject];
        if ([next isKindOfClass:UILabel.class]) {
            NSString *value = ((UILabel *)next).text;
            if ([value isEqualToString:@"Unknown Protocol"] ||
                [value isEqualToString:localized]) return YES;
        }
        [queue addObjectsFromArray:next.subviews];
    }
    return NO;
}

// Reynard's Swift WebContentErrorView stores an advancedBackButton and wires
// it to the native tabManager.goBack() handler. Access it only when the
// runtime exposes a real, object-typed ivar; otherwise use the homepage fallback.
static UIButton *CGBackButtonIfAvailable(UIView *errorView) {
    for (Class klass = object_getClass(errorView);
         klass && klass != UIView.class && klass != NSObject.class;
         klass = class_getSuperclass(klass)) {
        unsigned int count = 0;
        Ivar *ivars = class_copyIvarList(klass, &count);
        UIButton *button = nil;
        for (unsigned int i = 0; i < count; ++i) {
            Ivar ivar = ivars[i];
            const char *name = ivar_getName(ivar);
            const char *encoding = ivar_getTypeEncoding(ivar);
            if (!name || !encoding || encoding[0] != '@') continue;
            if (!strstr(name, "advancedBackButton")) continue;
            id value = object_getIvar(errorView, ivar);
            if ([value isKindOfClass:UIButton.class]) {
                button = value;
                break;
            }
        }
        free(ivars);
        if (button) return button;
    }
    return nil;
}

static void CGAttemptUnknownProtocolRecovery(UIView *errorView) {
    if (!errorView.window || errorView.hidden ||
        !CGHasUnknownProtocolTitle(errorView)) return;
    UIWindow *window = errorView.window;
    UIViewController *controller = window.rootViewController;
    if (!controller) return;

    // Prefer Reynard's native Back action when its history control says
    // that Back is possible. This preserves the user's current website.
    UIButton *back = CGBackButtonIfAvailable(errorView);
    if (back && !back.hidden && back.enabled) {
        [back sendActionsForControlEvents:UIControlEventTouchUpInside];
    }

    // If Back was unavailable or did not leave the error screen, recover
    // through the app's existing saved-homepage navigation path. A one-shot
    // token prevents retries and redirect loops for the same presentation.
    __weak UIView *weakErrorView = errorView;
    __weak UIViewController *weakController = controller;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                 (int64_t)(1.6 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        UIView *view = weakErrorView;
        UIViewController *root = weakController;
        if (!view || !root || !view.window || view.hidden ||
            view.window.rootViewController != root ||
            !CGHasUnknownProtocolTitle(view)) return;
        CGKioskRecoverHome(root);
    });
}

static void CGErrorViewSetHidden(UIView *self, SEL _cmd, BOOL hidden) {
    ((void (*)(id, SEL, BOOL))CGOriginalErrorSetHidden)(self, _cmd, hidden);
    if (hidden) {
        objc_setAssociatedObject(self, &CGUnknownProtocolHandledKey, nil,
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        return;
    }
    // configure(error:canGoBack:) calls setHidden before updating the labels.
    // Examine the finished view on the next run-loop tick, once per error.
    if (objc_getAssociatedObject(self, &CGUnknownProtocolHandledKey)) return;
    objc_setAssociatedObject(self, &CGUnknownProtocolHandledKey, @YES,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    __weak UIView *weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                 (int64_t)(0.10 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        UIView *view = weakSelf;
        if (!view || !view.window || view.hidden ||
            !CGHasUnknownProtocolTitle(view)) {
            if (view) objc_setAssociatedObject(
                view, &CGUnknownProtocolHandledKey, nil,
                OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            return;
        }
        CGAttemptUnknownProtocolRecovery(view);
    });
}

void CGInstallRuntimeRecovery(void) {
    if (CGRuntimeHookInstalled) return;
    Class klass = NSClassFromString(@"Reynard.WebContentErrorView");
    if (!klass) return;
    Method base = class_getInstanceMethod(UIView.class, @selector(setHidden:));
    if (!base) return;
    CGOriginalErrorSetHidden = method_getImplementation(base);
    class_replaceMethod(klass, @selector(setHidden:),
                        (IMP)CGErrorViewSetHidden,
                        method_getTypeEncoding(base));
    CGRuntimeHookInstalled = YES;
}
