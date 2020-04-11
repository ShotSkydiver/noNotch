#include "NTCRootListController.h"
#import <UIKit/UIColor+Private.h>
#import <CepheiPrefs/HBAppearanceSettings.h>
#import <Preferences/PSSpecifier.h>
#import <Preferences/PSTableCell.h>

@implementation NTCRootListController

#pragma mark - HBListController

+ (NSString *)hb_shareText {
	return [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"SHARE_TEXT", @"Root", [NSBundle bundleForClass:self], @"Default text for sharing the tweak. %@ is the device type (ie, iPhone)."), [UIDevice currentDevice].localizedModel];
}

+ (NSURL *)hb_shareURL {
    return [NSURL URLWithString:@"https://shade-zepheri.github.io/"];
}

+ (NSString *)hb_specifierPlist {
    return @"Root";
}

#pragma mark - PSListController

- (void)viewDidLoad {
    [super viewDidLoad];

    HBAppearanceSettings *appearance = [[HBAppearanceSettings alloc] init];
    appearance.tintColor = [UIColor purpleColor];
    appearance.navigationBarTintColor = [UIColor yellowColor];
    appearance.navigationBarBackgroundColor = [UIColor purpleColor];
    appearance.navigationBarTitleColor = [UIColor greenColor];
    appearance.statusBarTintColor = [UIColor blueColor];
    appearance.tableViewCellTextColor = [UIColor whiteColor];
    appearance.tableViewCellBackgroundColor = [UIColor colorWithWhite:22.f / 255.f alpha:1];
    appearance.tableViewCellSeparatorColor = [UIColor colorWithWhite:38.f / 255.f alpha:1];
    appearance.tableViewCellSelectionColor = [UIColor colorWithWhite:46.f / 255.f alpha:1];
    appearance.tableViewBackgroundColor = [UIColor colorWithWhite:44.f / 255.f alpha:1];
    self.hb_appearanceSettings = appearance;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    UIBarButtonItem *applyButton = [[UIBarButtonItem alloc] initWithTitle:@"Respring" style:UIBarButtonItemStylePlain target:self action:@selector(hb_respring)];
    self.navigationItem.rightBarButtonItem = applyButton;
}

@end
