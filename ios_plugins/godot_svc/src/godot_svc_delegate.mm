/*************************************************************************/
/*  godot_svc_delegate.mm                                                */
/*************************************************************************/
#import "platform/iphone/view_controller.h"
#import <UIKit/UIKit.h>
#import "WebKit/WebKit.h"
#import <SafariServices/SafariServices.h>

@interface GodotSvcDelegate : NSObject
- (void)loadSvc:(NSString *)url;
- (void)closeSvc;
@end

@implementation GodotSvcDelegate
- (void)loadSvc:(NSString *)url {
    // Parses String Into URL Request
    NSURL *nsurl=[NSURL URLWithString:url];
    // Gets root controller to present the safari view controller
    UIViewController *root_controller = [[UIApplication sharedApplication] delegate].window.rootViewController;
    // add svc
    SFSafariViewController *svc = [[SFSafariViewController alloc] initWithURL:nsurl];
    svc.delegate = (id) self;
    [root_controller presentViewController:svc animated:YES completion:nil];
}

- (void)closeSvc {
    UIViewController *root_controller = [[UIApplication sharedApplication] delegate].window.rootViewController;
    [root_controller dismissViewControllerAnimated:true completion:nil];
    
}
- (void)safariViewControllerDidFinish:(SFSafariViewController *)controller {
    UIViewController *root_controller = [[UIApplication sharedApplication] delegate].window.rootViewController;
    [root_controller dismissViewControllerAnimated:true completion:nil];
}
@end

