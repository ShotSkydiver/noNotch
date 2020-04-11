#import <UIKit/UIKit.h>
#import <_Prefix/IOSMacros.h>
#import <AppSupport/CPDistributedMessagingCenter.h>
#import <Cephei/HBPreferences.h>
#import <CoreGraphics/CoreGraphics.h>
#import <rocketbootstrap/rocketbootstrap.h>
#import <SpringBoard/SpringBoard.h>
#import <UIKit/UIStatusBar.h>

CPDistributedMessagingCenter *messagingCenter; //message center

UIWindow *noNotchW; //window which will contain everything
UIView *noNotch; //the black border which will cover the notch
UIView *cover; //a supporting view which will help us hide and show the status bar
UIInterfaceOrientation oldOrientation;

static BOOL enabled;
static CGFloat notchCoverHeight;

//our hide and show methods. Add a nice transition
void hide() {
    [UIView animateWithDuration:0.5 animations:^{
        noNotchW.alpha = 0.0;
    }];
}

void show() {
    if (oldOrientation != UIInterfaceOrientationPortrait) {
        return;
    }

    [UIView animateWithDuration:0.5 animations:^{
        noNotchW.alpha = 1.0;
    }];
}

void hideSB() {
    [UIView animateWithDuration:0.5 animations:^{
        cover.alpha = 0.0;
    }];
}

void showSB() {
    [UIView animateWithDuration:0.5 animations:^{
        cover.alpha = 1.0;
    }];
}

@interface SpringBoard ()
-(BOOL)isShowingHomescreen;
@end

@interface UIApplication ()
- (UIInterfaceOrientation)activeInterfaceOrientation;
@end

@interface UIStatusBarWindow : UIWindow
@end

@interface UIStatusBarWindow () <UIAccelerometerDelegate>
@end

@interface _UIStatusBar : UIView
@property (nonatomic, retain) UIColor *foregroundColor;
@end

BOOL isOnSpringBoard() {
    return [(SpringBoard *)[UIApplication sharedApplication] isShowingHomescreen];
}

%group SBHooks
%hook UIStatusBarWindow

- (void)layoutSubviews {    
    CGRect wholeFrame = [UIScreen mainScreen].bounds; //whole screen
    CGRect sbFrame = wholeFrame;
    sbFrame.size.height = 42;
    CGRect frame = CGRectMake(-50, notchCoverHeight, wholeFrame.size.width + 100, wholeFrame.size.height + 200); //this is the border which will cover the notch
    // for frame above: -16 changes the height of the notch frame
    if (!noNotchW) {
        [messagingCenter registerForMessageName:@"hide" target:self selector:@selector(hide:)];
        [messagingCenter registerForMessageName:@"hide2" target:self selector:@selector(hide:)]; //apps need special treatment
        [messagingCenter registerForMessageName:@"show" target:self selector:@selector(show:)];
        
        noNotchW = [[UIWindow alloc] initWithFrame:sbFrame]; //window will be as small as the status bar
        cover = [[UIView alloc] initWithFrame:sbFrame]; //the support view
    }
    
    if (!noNotch) {
        noNotch = [[UIView alloc] initWithFrame:frame]; //the notch view
    }

    noNotch.layer.borderColor = [UIColor blackColor].CGColor; //add a black border
    noNotch.layer.borderWidth = 50.0; //something thinner than the status bar
    
    noNotch.clipsToBounds = YES; //we want the border to be round
    noNotch.layer.masksToBounds = YES; //^^
    noNotch.layer.cornerRadius = 70; //corner radius
    
    noNotchW.windowLevel = 1096;
    noNotchW.hidden = NO; //we don't want it hidden for whatever reason
    noNotchW.userInteractionEnabled = YES; //touches will pass through the window
    noNotch.userInteractionEnabled = NO; //they won't pass through the notch cover because that's big and will block touches
    cover.userInteractionEnabled = YES; //touches will pass through the status bar
    
    [noNotchW addSubview:noNotch]; //add the notch cover inside the window
    UIStatusBar_Base *statusBar = [self valueForKey:@"_statusBar"];
    ((UIView *)statusBar).tag = 414141;
    [cover addSubview:(UIView *)statusBar]; //add status bar inside our supporting view
    [noNotchW addSubview:cover]; //add supporting view inside the window
    
    %orig; //make SpringBoard do whatever it was gonna do before we kicked in and stole the notch
}

- (void)setOrientation:(UIInterfaceOrientation)orientation animationParameters:(id)parameters {
    %orig;

    if (orientation == oldOrientation) {
        return;
    }

    oldOrientation = orientation;

    if (orientation == UIInterfaceOrientationPortrait && noNotchW.alpha != 1.0) {
        show();
    } else if (oldOrientation != UIInterfaceOrientationPortrait && noNotchW.alpha != 0.0) {
        hide();
    }
}

%new
- (void)hide:(NSString *)name {
    if ([name isEqualToString:@"hide2"] && isOnSpringBoard()) {
        return;   
    }

    [UIView animateWithDuration:1.0 animations:^{
        noNotchW.alpha = 0.0;
    }];
}

%new
- (void)show:(NSString *)name {
    [UIView animateWithDuration:1.0 animations:^{
        noNotchW.alpha = 1.0;
    }];
}

%end

//status bar window always visible
%hook UIStatusBarWindow

- (void)setHidden:(BOOL)hidden {
    %orig(NO);
}

%end

//status bar always visible
%hook UIStatusBar_Base

- (void)setAlpha:(CGFloat)alpha {
    //if the system wants to show the status bar make sure the notch cover window is also there
    if (alpha == 1.0 && noNotchW.alpha == 0.0) {
        show();
    }

    if (((UIView *)self).tag == 414141) {
        %orig(1.0);
    } else {
        %orig(alpha);
    }
}

%end

//align the status bar properly
%hook _UIStatusBar

- (void)setFrame:(CGRect)frame {
    frame.origin.y = -2;
    frame.size.height = 42;
    %orig(frame);
}

- (CGRect)bounds {
    CGRect frame = %orig;
    frame.origin.y = -2;
    frame.size.height = 42;
    return frame;
}

//make the status bar always white
- (void)layoutSubviews {
    %orig;
    self.foregroundColor = [UIColor whiteColor];
}

%end


//when we open an app make sure the notch cover is visible
/*%hook SpringBoard
-(void)frontDisplayDidChange:(id)newDisplay {
    %orig;
    
    if ([newDisplay isKindOfClass:%c(SBApplication)]) {
        if (cover.alpha == 0)
            showSB();
        if (noNotchW.alpha == 0)
            show();
    }
    
}
%end*/

%hook SBControlCenterController

//when control center is opened hide the status bar
- (void)presentAnimated:(BOOL)animated completion:(id)completion {
    if (cover.alpha != 0.0) {
        hideSB();
    }

    %orig;
}

//when control center is dismissed show the status bar
- (void)dismissAnimated:(BOOL)animated completion:(id)completion {
    if (cover.alpha == 0.0) {
        showSB();
    }

    %orig;
}

- (void)grabberTongueBeganPulling:(id)arg1 withDistance:(double)arg2 andVelocity:(double)arg3 {
    if (cover.alpha != 0.0) {
        hideSB();
    }

    %orig;
}

- (void)_willPresent {
    if (cover.alpha != 0.0) {
        hideSB();
    }

    %orig;
}

- (void)_didDismiss {
    if (cover.alpha == 0.0) {
        showSB();
    }

    %orig;
}

%end

//get rid of the notch cover when user enters wiggle mode. Can't think of an alternative
%hook SBIconController

- (void)setIsEditing:(BOOL)editing withFeedbackBehavior:(id)behavior {
    if (!editing && noNotchW.alpha != 1.0) {
        show();
    } else if (editing && noNotchW.alpha != 0.0) {
        hide();
    }

    %orig;
}

%end
%end

%group AppHooks
//if status bar is hidden => fullscreen app, therefore we need to hide the notch cover
%hook UIStatusBar_Base
- (void)setAlpha:(CGFloat)alpha {
    if (alpha == 0.0) {
        [messagingCenter sendMessageName:@"hide2" userInfo:nil];
    } else {
        [messagingCenter sendMessageName:@"show" userInfo:nil];
    }

    %orig(alpha);
}

- (void)setHidden:(BOOL)hidden {
    if (hidden) {
        [messagingCenter sendMessageName:@"hide2" userInfo:nil];
    } else {
        [messagingCenter sendMessageName:@"show" userInfo:nil];
    }

    %orig(hidden);
}

- (CGFloat)alpha {
    CGFloat alpha = %orig;
    if (alpha == 0.0) {
        [messagingCenter sendMessageName:@"hide2" userInfo:nil];
    } else {
        [messagingCenter sendMessageName:@"show" userInfo:nil];
    }

    return alpha;
}

- (BOOL)isHidden {
    BOOL hidden = %orig;
    if (hidden) {
        [messagingCenter sendMessageName:@"hide2" userInfo:nil];
    } else {
        [messagingCenter sendMessageName:@"show" userInfo:nil];
    }

    return hidden;
}

%end

//check again after we reopen the app. This doesn't seem to be working that well
%hook UIApplicationDelegate

- (void)applicationDidBecomeActive:(UIApplication *)application {
    if ([[[application valueForKey:@"statusBarWindow"] valueForKey:@"statusBar"] alpha] == 0.0 || [[[application valueForKey:@"statusBarWindow"] valueForKey:@"statusBar"] isHidden]) {
        [messagingCenter sendMessageName:@"hide" userInfo:nil];
    }

    %orig;
}

%end
%end

%ctor {
    messagingCenter = [CPDistributedMessagingCenter centerNamed:@"com.jakeashacks.noNotch"]; //setup our message center
    rocketbootstrap_distributedmessagingcenter_apply(messagingCenter); //use rocketbootstrap to get around sandbox limits
    
    if (IN_SPRINGBOARD) {
        [messagingCenter runServerOnCurrentThread];
        %init(SBHooks);

        // Load prefs
        HBPreferences *preferences = [HBPreferences preferencesForIdentifier:@"com.shade.nonotch"];
        [preferences registerBool:&enabled default:NO forKey:@"enabled"]; 
        [preferences registerFloat:&notchCoverHeight default:-18 forKey:@"notchCoverHeight"]; 

        // Callback
        [preferences registerPreferenceChangeBlock:^{
            // Show or hide if needed
            if (enabled) {
                show();
            } else {
                hide();
            }
        }];

        // Apply stuff when SB loaded
        NSNotificationCenter * __weak center = [NSNotificationCenter defaultCenter];
        id __block token = [center addObserverForName:UIApplicationDidFinishLaunchingNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notification) {
            if (enabled) {
                // Do nothing
                return;
            }

            // Hide if disabled
            hide();

            // Deregister as only created once
            [center removeObserver:token];
        }];
    } else {
        %init(AppHooks);
    }
}


    

