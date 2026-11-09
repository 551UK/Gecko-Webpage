#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <sqlite3.h>

// Reynard 0.19.0 kiosk hardening. All hooks are scoped to Gecko-Webpage's
// injected dylib, not the original Reynard or other applications.

static IMP CGOriginalUIViewHiddenSetter = NULL;
static IMP CGOriginalToolbarBoundsGetter = NULL;
static char CGOwnedLayoutConstraintsKey;

static void CGChromeStayHidden(id self, SEL _cmd, BOOL hidden) {
    if (CGOriginalUIViewHiddenSetter) {
        ((void (*)(id, SEL, BOOL))CGOriginalUIViewHiddenSetter)(self, _cmd, YES);
    }
}
static id CGChromeNoHitTesting(id self, SEL _cmd, CGPoint point, UIEvent *event) {
    // BrowserChrome overrides hitTest and can intercept touches even when
    // its address bar is visually absent.
    return nil;
}
static CGRect CGBottomToolbarZeroHeight(id self, SEL _cmd) {
    CGRect bounds = CGRectZero;
    if (CGOriginalToolbarBoundsGetter) {
        bounds = ((CGRect (*)(id, SEL))CGOriginalToolbarBoundsGetter)(self, _cmd);
    }
    bounds.size.height = 0;
    return bounds;
}
static void CGDisableChromeInteraction(UIView *view) {
    if (!view) return;
    view.hidden = YES;
    view.userInteractionEnabled = NO;
    for (UIGestureRecognizer *recognizer in view.gestureRecognizers)
        recognizer.enabled = NO;
    for (UIView *subview in view.subviews)
        CGDisableChromeInteraction(subview);
}

void CGInstallImprovements(void) {
    Method hidden = class_getInstanceMethod(UIView.class, @selector(setHidden:));
    if (hidden) {
        CGOriginalUIViewHiddenSetter = method_getImplementation(hidden);
        for (NSString *name in @[@"Reynard.BrowserChrome",
                                  @"Reynard.TabOverview"]) {
            Class klass = NSClassFromString(name);
            if (klass) class_replaceMethod(klass, @selector(setHidden:),
                (IMP)CGChromeStayHidden, method_getTypeEncoding(hidden));
        }
    }
    Class chrome = NSClassFromString(@"Reynard.BrowserChrome");
    if (chrome) {
        Method hit = class_getInstanceMethod(chrome, @selector(hitTest:withEvent:));
        if (hit) class_replaceMethod(chrome, @selector(hitTest:withEvent:),
            (IMP)CGChromeNoHitTesting, method_getTypeEncoding(hit));
    }
    Class toolbar = NSClassFromString(@"Reynard.BottomToolbar");
    if (toolbar) {
        Method bounds = class_getInstanceMethod(toolbar, @selector(bounds));
        if (bounds) {
            CGOriginalToolbarBoundsGetter = method_getImplementation(bounds);
            class_replaceMethod(toolbar, @selector(bounds),
                (IMP)CGBottomToolbarZeroHeight, method_getTypeEncoding(bounds));
        }
    }
}

void CGApplyFullscreen(UIViewController *controller) {
    UIView *root = controller.view;
    if (!root) return;
    UIView *chrome = nil, *overview = nil, *content = nil;
    for (UIView *view in root.subviews) {
        NSString *className = NSStringFromClass(view.class);
        if ([className hasSuffix:@".BrowserChrome"] ||
            [className isEqualToString:@"BrowserChrome"]) {
            chrome = view;
        } else if ([className hasSuffix:@".TabOverview"] ||
                   [className isEqualToString:@"TabOverview"]) {
            overview = view;
        } else if ([className hasSuffix:@".ContentView"] ||
                   [className isEqualToString:@"ContentView"]) {
            content = view;
        }
    }
    CGDisableChromeInteraction(chrome);
    CGDisableChromeInteraction(overview);
    if (!content) return;

    NSArray<NSLayoutConstraint *> *ours =
        objc_getAssociatedObject(content, &CGOwnedLayoutConstraintsKey);
    // Reynard refreshes its content anchors on rotation/toolbar transitions.
    // Remove those offsets without deactivating our own fullscreen anchors.
    for (NSLayoutConstraint *constraint in [root.constraints copy]) {
        if (!constraint.active || [ours containsObject:constraint]) continue;
        if (constraint.firstItem != content && constraint.secondItem != content) continue;
        BOOL vertical = constraint.firstAttribute == NSLayoutAttributeTop ||
                        constraint.firstAttribute == NSLayoutAttributeBottom ||
                        constraint.secondAttribute == NSLayoutAttributeTop ||
                        constraint.secondAttribute == NSLayoutAttributeBottom;
        if (vertical) constraint.active = NO;
    }
    if (!ours) {
        content.translatesAutoresizingMaskIntoConstraints = NO;
        ours = @[
            [content.topAnchor constraintEqualToAnchor:root.topAnchor],
            [content.bottomAnchor constraintEqualToAnchor:root.bottomAnchor]
        ];
        objc_setAssociatedObject(content, &CGOwnedLayoutConstraintsKey, ours,
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [NSLayoutConstraint activateConstraints:ours];
    } else {
        for (NSLayoutConstraint *constraint in ours)
            if (!constraint.active) constraint.active = YES;
    }
    // Prevent hidden overlays from taking priority over actual web touches.
    [root bringSubviewToFront:content];
}

static BOOL CGKnownAdRedirect(NSString *value) {
    if (!value.length) return NO;
    NSURLComponents *parts = [NSURLComponents componentsWithString:value];
    NSString *host = parts.host.lowercaseString;
    NSString *query = parts.percentEncodedQuery.lowercaseString ?: @"";
    // Target only the exact ad-redirect pattern reported in issue #491.
    return [host isEqualToString:@"dhan.go.link"] &&
           [query containsString:@"rdt_cid="];
}
static BOOL CGInvalidRestoredScheme(NSString *value) {
    if (!value.length) return NO;
    NSURLComponents *parts = [NSURLComponents componentsWithString:value];
    NSString *scheme = parts.scheme.lowercaseString;
    if (!scheme.length) return NO;
    // Internal Gecko pages are legitimate, as are local files.
    if ([@[@"http", @"https", @"about", @"file", @"resource",
           @"moz-extension"] containsObject:scheme]) return NO;
    return YES;
}
static NSString *CGStatementText(sqlite3_stmt *statement, int column) {
    const unsigned char *raw = sqlite3_column_text(statement, column);
    return raw ? [NSString stringWithUTF8String:(const char *)raw] : nil;
}
static void CGDeleteKnownAdTabs(sqlite3 *db, NSString *selectedID) {
    sqlite3_stmt *lookup = NULL;
    NSMutableArray<NSString *> *junkIDs = [NSMutableArray array];
    if (sqlite3_prepare_v2(db,
        "SELECT id, url FROM tabs WHERE is_private = 0;", -1, &lookup, NULL) == SQLITE_OK) {
        while (sqlite3_step(lookup) == SQLITE_ROW) {
            NSString *identifier = CGStatementText(lookup, 0);
            NSString *url = CGStatementText(lookup, 1);
            if (identifier.length && ![identifier isEqualToString:selectedID] &&
                CGKnownAdRedirect(url)) [junkIDs addObject:identifier];
        }
    }
    if (lookup) sqlite3_finalize(lookup);
    if (!junkIDs.count) return;
    sqlite3_stmt *remove = NULL;
    if (sqlite3_prepare_v2(db, "DELETE FROM tabs WHERE id = ?;", -1,
                           &remove, NULL) == SQLITE_OK) {
        for (NSString *identifier in junkIDs) {
            sqlite3_reset(remove);
            sqlite3_clear_bindings(remove);
            sqlite3_bind_text(remove, 1, identifier.UTF8String, -1, SQLITE_TRANSIENT);
            sqlite3_step(remove);
        }
    }
    if (remove) sqlite3_finalize(remove);
}

void CGRepairRestoredTabIfNecessary(NSString *homepage) {
    NSURLComponents *home = [NSURLComponents componentsWithString:homepage];
    if (!home.host.length ||
        ![@[@"http", @"https"] containsObject:home.scheme.lowercaseString]) return;

    NSURL *support = [[NSFileManager defaultManager]
        URLsForDirectory:NSApplicationSupportDirectory
               inDomains:NSUserDomainMask].firstObject;
    NSString *path = [[support URLByAppendingPathComponent:
                      @"AppData/TabManagement/TabManagement"] path];
    if (!path || ![[NSFileManager defaultManager] fileExistsAtPath:path]) return;

    sqlite3 *db = NULL;
    int rc = sqlite3_open_v2(path.UTF8String, &db,
              SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX, NULL);
    if (rc != SQLITE_OK) { if (db) sqlite3_close(db); return; }
    sqlite3_busy_timeout(db, 800);
    sqlite3_stmt *query = NULL;
    NSString *selectedID = nil, *selectedURL = nil;
    const char *sql = "SELECT t.id, t.url FROM tab_state s "
        "JOIN tabs t ON t.id = s.selected_regular_tab_id "
        "WHERE s.id = 1 AND s.selected_tab_mode = 'regular' LIMIT 1;";
    if (sqlite3_prepare_v2(db, sql, -1, &query, NULL) == SQLITE_OK &&
        sqlite3_step(query) == SQLITE_ROW) {
        selectedID = CGStatementText(query, 0);
        selectedURL = CGStatementText(query, 1);
    }
    if (query) sqlite3_finalize(query);

    if (sqlite3_exec(db, "BEGIN IMMEDIATE;", NULL, NULL, NULL) == SQLITE_OK) {
        // A bad last tab must not replace all healthy tabs or erase a login.
        if (selectedID.length &&
            (CGKnownAdRedirect(selectedURL) ||
             CGInvalidRestoredScheme(selectedURL))) {
            sqlite3_stmt *update = NULL;
            if (sqlite3_prepare_v2(db,
                "UPDATE tabs SET url = ?, title = ?, tab_session_state = NULL "
                "WHERE id = ? AND is_private = 0;", -1, &update, NULL) == SQLITE_OK) {
                sqlite3_bind_text(update, 1, homepage.UTF8String, -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(update, 2, home.host.UTF8String, -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(update, 3, selectedID.UTF8String, -1, SQLITE_TRANSIENT);
                sqlite3_step(update);
            }
            if (update) sqlite3_finalize(update);
        }
        CGDeleteKnownAdTabs(db, selectedID);
        sqlite3_exec(db, "COMMIT;", NULL, NULL, NULL);
    }
    sqlite3_close(db);
}
