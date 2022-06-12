/*************************************************************************/
/*  godot_svc.mm                                                         */
/*************************************************************************/
#include "godot_svc.h"

#import "platform/iphone/app_delegate.h"
#import "platform/iphone/view_controller.h"
#import "godot_svc_delegate.mm"
#import <Foundation/Foundation.h>

GodotSvc *GodotSvc::instance = NULL;
GodotSvcDelegate *godot_svc_delegate = nil;
void GodotSvc::_bind_methods() {
    ClassDB::bind_method(D_METHOD("popup"), &GodotSvc::popup);
    ClassDB::bind_method(D_METHOD("close"), &GodotSvc::close);
}

GodotSvc::GodotSvc() {
    ERR_FAIL_COND(instance != NULL);
    instance = this;
	godot_svc_delegate = [[GodotSvcDelegate alloc] init];
}

void GodotSvc::popup(String url){
    NSString *nsURL = [[NSString alloc] initWithUTF8String:url.utf8().get_data()];
    [godot_svc_delegate loadSvc:nsURL];
}

void GodotSvc::close(){
    [godot_svc_delegate closeSvc];
}

GodotSvc *GodotSvc::get_singleton() {
	return instance;
};

GodotSvc::~GodotSvc() {
    if (godot_svc_delegate) {
		godot_svc_delegate = nil;
	}
}
