//
//  UIViewController+Hook.m
//  HelloUniMPDemo
//
//  Created by tk-ios03 on 2020/4/16.
//  Copyright © 2020 DCloud. All rights reserved.
//

#import "UIViewController+Hook.h"
#import <objc/message.h>
#import <objc/runtime.h>
#import "PresentCustomAnimation.h"
#import "DismissCustomAnimation.h"
#import "AAPLSwipeTransitionInteractionController.h"

static NSString *nameWithSetterGetterKey = @"nameWithSetterGetterKey";

@interface UIViewController(Hook)
@property (nonatomic,strong) UIScreenEdgePanGestureRecognizer *gestureRecognizer;
@end

@implementation UIViewController (Hook)

+(void)loadHook{
    Method presentMethod = class_getInstanceMethod([UIViewController class], @selector(presentViewController:animated:completion:));
    Method pushMethod = class_getInstanceMethod([UIViewController class], @selector(hook_presentViewController:animated:completion:));
    method_exchangeImplementations(presentMethod, pushMethod);
    
    Method dismissMethod = class_getInstanceMethod([UIViewController class], @selector(dismissViewControllerAnimated:completion:));
    Method hook_dismissMethod = class_getInstanceMethod([UIViewController class], @selector(hook_dismissViewControllerAnimated:completion:));
    method_exchangeImplementations(dismissMethod, hook_dismissMethod);
}

-(void)hook_dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion{
    [self hook_dismissViewControllerAnimated:flag completion:completion];
//    if ([self isKindOfClass:NSClassFromString(@"DCUniMPViewController")] && [self.presentedViewController isKindOfClass:[UIAlertController class]] == NO){
//        self.transitioningDelegate = nil;
//    }
}

-(void)hook_presentViewController:(UIViewController *)viewControllerToPresent animated:(BOOL)flag completion:(void (^)(void))completion{
    if ([viewControllerToPresent isKindOfClass:NSClassFromString(@"DCUniMPViewController")]) {
        viewControllerToPresent.transitioningDelegate = self;
        UIScreenEdgePanGestureRecognizer *interactiveTransitionRecognizer;
        interactiveTransitionRecognizer = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self action:@selector(interactiveTransitionRecognizerAction:)];
        interactiveTransitionRecognizer.edges = UIRectEdgeLeft;
        [viewControllerToPresent.view addGestureRecognizer:interactiveTransitionRecognizer];
    }
    [self hook_presentViewController:viewControllerToPresent animated:flag completion:completion];
}

- (void)interactiveTransitionRecognizerAction:(UIScreenEdgePanGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateBegan) {
        self.gestureRecognizer = sender;
        UIView *view = sender.view;
        UIViewController *vc = [self traverseResponderChainForUIViewController:view];
        [vc dismissViewControllerAnimated:YES completion:^{
            [DCUniMPSDKEngine closeUniMP];
        }];
    }
}

-(id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source{
    NSLog(@"call fun:%s",__func__);
    return PresentCustomAnimation.new;
}

- (id<UIViewControllerInteractiveTransitioning>)interactionControllerForPresentation:(id<UIViewControllerAnimatedTransitioning>)animator
{
    // You must not return an interaction controller from this method unless
    // the transition will be interactive.
    NSLog(@"call fun:%s",__func__);
    return nil;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed{
    NSLog(@"call fun:%s",__func__);
    return DismissCustomAnimation.new;
}

- (id<UIViewControllerInteractiveTransitioning>)interactionControllerForDismissal:(id<UIViewControllerAnimatedTransitioning>)animator
{
    // You must not return an interaction controller from this method unless
    // the transition will be interactive.
    NSLog(@"call fun:%s",__func__);
    if (self.gestureRecognizer)
        return [[AAPLSwipeTransitionInteractionController alloc] initWithGestureRecognizer:self.gestureRecognizer edgeForDragging:UIRectEdgeLeft];
    else
        return nil;
}

- (void)setGestureRecognizer:(UIScreenEdgePanGestureRecognizer *)gestureRecognizer{
    objc_setAssociatedObject(self, &nameWithSetterGetterKey, gestureRecognizer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (UIScreenEdgePanGestureRecognizer *)gestureRecognizer{
    return objc_getAssociatedObject(self, &nameWithSetterGetterKey);
}

- (UIViewController *)traverseResponderChainForUIViewController:(UIView *)view{
    id nextResponder = [view nextResponder];
    if ([nextResponder isKindOfClass:[UIViewController class]]) {
        return nextResponder;
    } else if ([nextResponder isKindOfClass:[UIView class]]) {
        return [self traverseResponderChainForUIViewController:nextResponder];
    } else {
        return nil;
    }
}
@end
