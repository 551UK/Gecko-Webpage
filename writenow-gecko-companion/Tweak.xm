#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <substrate.h>

// A temporary native text view to reuse the ORIGINAL Write Now interface.
@interface WNGProxy : UITextView
@property (nonatomic, weak) UIView<UITextInput> *gecko;
@property (nonatomic, assign) NSUInteger offset;
@property (nonatomic, copy) NSString *expected;
@property (nonatomic, assign) BOOL active;
@end
@implementation WNGProxy
- (void)replaceRange:(UITextRange *)range withText:(NSString *)text {
  [super replaceRange:range withText:text];
  if (!self.active || !self.gecko || !text) return;
  UIView<UITextInput> *g = self.gecko;
  SEL editable = NSSelectorFromString(@"isEditable");
  if (![g respondsToSelector:editable]) return;
  BOOL (*isEditable)(id,SEL)=(BOOL (*)(id,SEL))[g methodForSelector:editable];
  if (!isEditable(g,editable)) return;
  UITextPosition *begin = g.beginningOfDocument;
  UITextPosition *start = begin ? [g positionFromPosition:begin offset:(NSInteger)self.offset] : nil;
  UITextPosition *end = start ? [g positionFromPosition:start offset:(NSInteger)self.expected.length] : nil;
  UITextRange *r = (start && end) ? [g textRangeFromPosition:start toPosition:end] : nil;
  if (!r || ![[g textInRange:r] isEqualToString:self.expected]) return;
  [g replaceRange:r withText:text];
  self.expected = text;
}
@end

static BOOL installed=NO;
static BOOL (*previousCan)(id,SEL,SEL,id)=NULL;
static const char *actionName="_WT_OpenTools_3cf98861";

static BOOL isEditableSelection(id view) {
  if (![view conformsToProtocol:@protocol(UITextInput)]) return NO;
  SEL editable=NSSelectorFromString(@"isEditable");
  if (![view respondsToSelector:editable]) return NO;
  BOOL (*isEditable)(id,SEL)=(BOOL (*)(id,SEL))[view methodForSelector:editable];
  if (!isEditable(view,editable)) return NO;
  id<UITextInput> input=(id<UITextInput>)view;
  UITextRange *range=input.selectedTextRange;
  return range && !range.empty && [input textInRange:range].length>0;
}
static BOOL canPerform(id self,SEL cmd,SEL action,id sender) {
  if (action==sel_registerName(actionName))
    return isEditableSelection(self) && [self respondsToSelector:action];
  return previousCan ? previousCan(self,cmd,action,sender) : NO;
}
static void openOriginalWriteNow(id view,SEL unused) {
  if (!isEditableSelection(view)) return;
  UIView<UITextInput> *gecko=(UIView<UITextInput> *)view;
  UITextRange *selection=gecko.selectedTextRange;
  NSString *selected=[[gecko textInRange:selection] copy];
  NSInteger offset=[gecko offsetFromPosition:gecko.beginningOfDocument toPosition:selection.start];
  if (offset<0 || !selected.length) return;
  CGRect r=[gecko firstRectForRange:selection];
  if (CGRectIsNull(r)||CGRectIsEmpty(r)) r=CGRectMake(8,8,160,32);
  r.origin.x=MAX(0,MIN(r.origin.x,MAX(0,gecko.bounds.size.width-120)));
  r.origin.y=MAX(0,MIN(r.origin.y,MAX(0,gecko.bounds.size.height-30)));
  r.size=CGSizeMake(MIN(240,MAX(120,r.size.width)),MAX(26,r.size.height));
  WNGProxy *proxy=[[WNGProxy alloc] initWithFrame:r];
  proxy.gecko=gecko;
  proxy.offset=(NSUInteger)offset;
  proxy.expected=selected;
  proxy.backgroundColor=UIColor.clearColor;
  proxy.textColor=UIColor.clearColor;
  proxy.tintColor=UIColor.clearColor;
  proxy.scrollEnabled=NO;
  proxy.editable=YES;
  proxy.selectable=YES;
  proxy.userInteractionEnabled=YES;
  proxy.alpha=0.02;
  proxy.text=selected;
  proxy.selectedRange=NSMakeRange(0,selected.length);
  [gecko addSubview:proxy];
  proxy.active=YES;
  SEL action=sel_registerName(actionName);
  if ([proxy respondsToSelector:action]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [proxy performSelector:action];
#pragma clang diagnostic pop
  } else [proxy removeFromSuperview];
  // Proxy is cleaned up with the webpage view; no changes to Write Now app.
}
static void installWhenGeckoExists(UIView *v) {
  if (installed) return;
  Class c=NSClassFromString(@"ChildView");
  if (!c || ![v isKindOfClass:c]) return;
  installed=YES;
  MSHookMessageEx(c,@selector(canPerformAction:withSender:),(IMP)canPerform,(IMP *)&previousCan);
  class_addMethod(c,sel_registerName(actionName),(IMP)openOriginalWriteNow,"v@:");
}
%hook UIView
- (void)didMoveToWindow {
  %orig;
  if (!installed) installWhenGeckoExists(self);
}
%end
%ctor {
  NSString *bid=NSBundle.mainBundle.bundleIdentifier;
  if ([bid isEqualToString:@"com.minh-ton.Reynard"] ||
      [bid isEqualToString:@"com.551uk.chatgptios16"]) { %init; }
}
