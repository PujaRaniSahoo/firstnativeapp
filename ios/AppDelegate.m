#import "AppDelegate.h"
#import "MendixAppDelegate.h"
#import "MendixNative/MendixNative.h"
#import "IQKeyboardManager/IQKeyboardManager.h"
#import "SplashScreenPresenter.h"

@implementation AppDelegate

@synthesize shouldOpenInLastApp;

- (BOOL) application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  MendixAppDelegate.delegate = self;
  [MendixAppDelegate application:application didFinishLaunchingWithOptions:launchOptions];
  [self setupUI];

  NSBundle *mainBundle = [NSBundle mainBundle];
  NSString *targetName = [mainBundle objectForInfoDictionaryKey:@"TargetName"] ?: @"";

  if ([targetName isEqual: @"dev"]) {
    IQKeyboardManager.sharedManager.enable = NO;

    self.window = [[MendixReactWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"LaunchApp" bundle:nil];
    self.window.rootViewController = [storyboard instantiateInitialViewController];
    [self.window makeKeyAndVisible];
    [self.window setUserInteractionEnabled:YES];

    NSString *url = [AppPreferences getAppUrl];
    if (launchOptions == nil || url == nil) {
      return YES;
    }

    shouldOpenInLastApp = YES;
    NSURL *bundleUrl = [AppUrl forBundle:url port:[AppPreferences getRemoteDebuggingPackagerPort] isDebuggingRemotely:[AppPreferences remoteDebuggingEnabled] isDevModeEnabled:[AppPreferences devModeEnabled]];
    NSURL *runtimeUrl = [AppUrl forRuntime:url];
    MendixApp *mendixApp = [[MendixApp alloc] init:nil bundleUrl:bundleUrl runtimeUrl:runtimeUrl warningsFilter:[self getWarningFilterValue] isDeveloperApp:YES clearDataAtLaunch:NO];
    [ReactNative.instance setup:mendixApp launchOptions:launchOptions];

    return YES;
  }

  self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
  self.window.rootViewController = [UIViewController new];
  [self.window makeKeyAndVisible];

  NSString *url = [mainBundle objectForInfoDictionaryKey:@"Runtime url"];
  if (url == nil || [url length] == 0) {
    [self showUnrecoverableDialogWithTitle:@"The runtime URL is missing" message:@"Missing the 'Runtime url' configuration within the Info.plist file. The app will close."];
    return NO;
  }
  NSURL *runtimeUrl = [AppUrl forRuntime:[url stringByReplacingOccurrencesOfString:@"\\" withString:@""]];
  NSURL *bundleUrl = [ReactNative.instance getJSBundleFile];

  if (bundleUrl != nil) {
    [ReactNative.instance setup:[[MendixApp alloc] init:nil bundleUrl:bundleUrl runtimeUrl:runtimeUrl warningsFilter:none isDeveloperApp:NO clearDataAtLaunch:NO splashScreenPresenter:[SplashScreenPresenter new]] launchOptions:launchOptions];
    [ReactNative.instance start];
  } else {
    [self showUnrecoverableDialogWithTitle:@"No Mendix bundle found" message:@"Missing the Mendix app bundle. Make sure that the index.ios.bundle file is available in ios/NativeTemplate/Bundle folder. If building locally consult the documentation on how to generate a bundle from your project."];
  }

  return YES;
}

- (void) application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
  [MendixAppDelegate application:application didReceiveLocalNotification:notification];
}

- (void) application:(UIApplication *)application didReceiveRemoteNotification:(nonnull NSDictionary *)userInfo
fetchCompletionHandler:(nonnull void (^)(UIBackgroundFetchResult))completionHandler{
  [MendixAppDelegate application:application didReceiveRemoteNotification:userInfo fetchCompletionHandler:completionHandler];
}

- (void) application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
  [MendixAppDelegate application:application didRegisterUserNotificationSettings:notificationSettings];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
  [MendixAppDelegate application:application openURL:url sourceApplication:sourceApplication annotation:annotation];
  return YES;
}

- (WarningsFilter) getWarningFilterValue {
#if DEBUG
  return all;
#else
  return [AppPreferences devModeEnabled] ? partial : none;
#endif
}

- (void) showUnrecoverableDialogWithTitle:(NSString *)title message:(NSString *) message {
  UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
  [alertController addAction:[UIAlertAction actionWithTitle:@"Close" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
    [NSException raise:@"UnrecoverableError" format:message];
  }]];
  [self.window.rootViewController presentViewController:alertController animated:YES completion:nil];
}

- (void) setupUI {
  if (@available(iOS 13.4, *)) {
    [UIDatePicker appearance].preferredDatePickerStyle = UIDatePickerStyleWheels;
  }
}

- (void) userNotificationCenter:(UNUserNotificationCenter *)center
        willPresentNotification:(UNNotification *)notification
          withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler {
  [MendixAppDelegate userNotificationCenter:center willPresentNotification:notification withCompletionHandler:completionHandler];
}

- (void) userNotificationCenter:(UNUserNotificationCenter *)center
    didReceiveNotificationResponse:(UNNotificationResponse *)response
             withCompletionHandler:(void (^)(void))completionHandler {
  [MendixAppDelegate userNotificationCenter:center didReceiveNotificationResponse:response withCompletionHandler:completionHandler];
}
@end
