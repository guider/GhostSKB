//
//  AppDelegate.m
//  testApp
//
//  Created by 丁明信 on 4/4/16.
//  Copyright © 2016 丁明信. All rights reserved.
//

#import "AppDelegate.h"
#import "PopoverViewController.h"
#import "GHDefaultManager.h"
#import "Constant.h"

#import <AppKit/AppKit.h>
#import <Carbon/Carbon.h>
#import <ApplicationServices/ApplicationServices.h>
@interface AppDelegate ()


@end


@implementation AppDelegate
@synthesize settingWinCon;
#pragma mark - App Life Cycle


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {

    NSNotificationCenter *nc = [[NSWorkspace sharedWorkspace] notificationCenter];
    [nc addObserver:self selector:@selector(handleAppActivateNoti:) name:NSWorkspaceDidActivateApplicationNotification object:NULL];
    [nc addObserver:self selector:@selector(handleAppUnhideNoti:) name:NSWorkspaceDidUnhideApplicationNotification object:NULL];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleGHAppSelectedNoti:) name:@"GH_APP_SELECTED" object:NULL];
    [GHDefaultManager getInstance];
    
    [self initStatusItem];
    [self initPopover];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (void)awakeFromNib {
    [imenu setDelegate:self];
}

- (void)initPopover {
    popover = [[NSPopover alloc] init];
    popover.behavior = NSPopoverBehaviorTransient;
    popover.contentViewController = [[PopoverViewController alloc] init];
}

- (void)initStatusItem {
    statusItemSelected = false;
    NSString *imageName = @"ghost_dark_small";
    NSImage *normalImage = [NSImage imageNamed:imageName];
    [normalImage setTemplate:YES];
    
    statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    statusItem.highlightMode = YES;
    statusItem.image = normalImage;
    
    [statusItem.button setAction:@selector(onStatusItemSelected:)];
}

- (void) onStatusItemSelected:(id) sender {
    statusItemSelected = !statusItemSelected;
    [self showPopover:sender];
}

- (void)showPopover:(id)sender {
    NSStatusBarButton* button = statusItem.button;
    _statusBarButton = button;
    if (popover.isShown) {
        [popover performClose:button];
    }
    else {
        //get forcus
        [[NSRunningApplication currentApplication] activateWithOptions:NSApplicationActivateIgnoringOtherApps];
        //show popover
        [popover showRelativeToRect:button.bounds ofView:button preferredEdge:NSRectEdgeMaxY];
    }
}

- (NSMutableString *)getCurrentInputSourceId
{
    TISInputSourceRef inputSource = TISCopyCurrentKeyboardInputSource();
    NSMutableString *inputId = (__bridge NSMutableString *)(TISGetInputSourceProperty(inputSource, kTISPropertyInputSourceID));
    return inputId;
}

- (void)doChangeInputSource:(NSString *)targetInputId
{
    TISInputSourceRef inputSource = NULL;
    TISInputSourceRef currentInputSource = TISCopyCurrentKeyboardInputSource();
    NSMutableString *currentInputSourceId = (__bridge NSMutableString *)(TISGetInputSourceProperty(currentInputSource, kTISPropertyInputSourceID));
    if ([targetInputId isEqualToString:currentInputSourceId]) {
        return;
    }
    NSDictionary *property=[NSDictionary dictionaryWithObject:(NSString*)kTISCategoryKeyboardInputSource
                                                      forKey:(NSString*)kTISPropertyInputSourceCategory];
    CFArrayRef availableInputs = TISCreateInputSourceList((__bridge CFDictionaryRef)property, false);
    NSUInteger count = CFArrayGetCount(availableInputs);
    
    
    
    for (int i = 0; i < count; i++) {
        inputSource = (TISInputSourceRef)CFArrayGetValueAtIndex(availableInputs, i);
        
        //获取输入源的id
        NSMutableString *inputSourceId = (__bridge NSMutableString *)(TISGetInputSourceProperty(inputSource, kTISPropertyInputSourceID));
        if ([inputSourceId isEqualToString:targetInputId]) {
            NSNumber* pIsSelectCapable = (__bridge NSNumber*)(TISGetInputSourceProperty(inputSource, kTISPropertyInputSourceIsSelectCapable));
            BOOL canSelect = [pIsSelectCapable boolValue];
            
            NSNumber *pIsEnableCapable= (__bridge NSNumber *)(TISGetInputSourceProperty(inputSource, kTISPropertyInputSourceIsEnableCapable));
            BOOL canEnable = [pIsEnableCapable boolValue];
            if (canEnable) {
                TISEnableInputSource(inputSource);
            }
            if (canSelect) {
                TISSelectInputSource(inputSource);
            }
            
            break;
        }
    }
}

- (void) handleAppUnhideNoti:(NSNotification *)noti {
    NSRunningApplication *runningApp = (NSRunningApplication *)[noti.userInfo objectForKey:@"NSWorkspaceApplicationKey"];
    NSString *identifier = runningApp.bundleIdentifier;
    [self changeInputSourceForApp:identifier];
}

- (void) handleAppActivateNoti:(NSNotification *)noti {
    
    _lastAppInputSourceId = [self getCurrentInputSourceId];
    NSRunningApplication *runningApp = (NSRunningApplication *)[noti.userInfo objectForKey:@"NSWorkspaceApplicationKey"];
    NSString *identifier = runningApp.bundleIdentifier;
    [self changeInputSourceForApp:identifier];
}

- (void)changeInputSourceForApp:(NSString *)bundleId {
    NSString *targetInputId = NULL;
    NSDictionary *defaultInput = [[GHDefaultManager getInstance] getDefaultKeyBoardsDict];
    NSDictionary *info = [defaultInput objectForKey:bundleId];
    targetInputId = [[info objectForKey:@"defaultInput"] description];
    
    if (targetInputId != NULL) {
//        [self doChangeInputSource:targetInputId];
        [self performSelector:@selector(doChangeInputSource:) withObject:targetInputId afterDelay:0.01];
    }
}

- (void) changeStatusItemImage:(BOOL)isLight {
    if (isLight) {
        statusItem.image = [NSImage imageNamed:@"ghost_white_small"];
    }
    else {
        statusItem.image =[NSImage imageNamed:@"ghost_dark_small"];
    }
}
- (void) handleGHAppSelectedNoti:(NSNotification *)noti {
    //get forcus
    [[NSRunningApplication currentApplication] activateWithOptions:NSApplicationActivateIgnoringOtherApps];
    //show popover
    [popover showRelativeToRect:_statusBarButton.bounds ofView:_statusBarButton preferredEdge:NSRectEdgeMaxY];
}

- (void)showSettingWindow {
    if (self.settingWinCon == NULL) {
        self.settingWinCon = [[GHSettingWindowControler alloc] init];
    }
    
    [self.settingWinCon showWindow:NULL];

}


@end
