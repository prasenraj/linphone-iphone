/* PhoneMainView.m
 *
 * Copyright (C) 2012  Belledonne Comunications, Grenoble, France
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or   
 *  (at your option) any later version.                                 
 *                                                                      
 *  This program is distributed in the hope that it will be useful,     
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of      
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the       
 *  GNU General Public License for more details.                
 *                                                                      
 *  You should have received a copy of the GNU General Public License   
 *  along with this program; if not, write to the Free Software         
 *  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */   

#import "PhoneMainView.h"
#import "PhoneViewController.h"
#import "HistoryViewController.h"
#import "ContactsViewController.h"
#import "InCallViewController.h"

typedef enum _TabBar {
    TabBar_Main,
    TabBar_END
} TabBar;


@interface ViewsDescription: NSObject{
    @public
    UIViewController *content;
    UIViewController *tabBar;
    bool statusEnabled;
}
@end
@implementation ViewsDescription
@end

@implementation PhoneMainView

@synthesize stateBarView;
@synthesize contentView;
@synthesize tabBarView;

@synthesize stateBarController;

@synthesize callTabBarController;
@synthesize mainTabBarController;
@synthesize incomingCallTabBarController;

- (void)changeView: (NSNotification*) notif {   
    PhoneView view = [[notif.userInfo objectForKey: @"view"] intValue];
    ViewsDescription *description = [viewDescriptions objectForKey:[NSNumber numberWithInt: view]];
    
    for (UIView *view in contentView.subviews) {
        [view removeFromSuperview];
    }
    for (UIView *view in tabBarView.subviews) {
        [view removeFromSuperview];
    }
    if(description == nil)
        return;
    
    UIView *innerView = description->content.view;
    [contentView addSubview: innerView];
    
    CGRect contentFrame = contentView.frame;
    if(description->statusEnabled) {
        stateBarView.hidden = false;
        contentFrame.origin.y = stateBarView.frame.size.height + stateBarView.frame.origin.y;
    } else {
        stateBarView.hidden = true;
        contentFrame.origin.y = 0;
    }
    
    // Resize tabbar
    CGRect tabFrame = tabBarView.frame;
    if(description->tabBar != nil) {
        tabBarView.hidden = false;
        tabFrame.origin.y += tabFrame.size.height;
        tabFrame.origin.x += tabFrame.size.width;
        tabFrame.size.height = description->tabBar.view.frame.size.height;
        tabFrame.size.width = description->tabBar.view.frame.size.width;
        tabFrame.origin.y -= tabFrame.size.height;
        tabFrame.origin.x -= tabFrame.size.width;
        [tabBarView setFrame: tabFrame];
        contentFrame.size.height = tabFrame.origin.y - contentFrame.origin.y;
        for (UIView *view in description->tabBar.view.subviews) {
            if(view.tag == -1) {
                contentFrame.size.height += view.frame.origin.y;
                break;
            }
        }
        [tabBarView addSubview: description->tabBar.view];
    } else {
        tabBarView.hidden = true;
        contentFrame.size.height = tabFrame.origin.y - tabFrame.size.height;
    }
    
    [contentView setFrame: contentFrame];
    CGRect innerContentFrame = innerView.frame;
    innerContentFrame.size = contentFrame.size;
    [innerView setFrame: innerContentFrame];
    
    NSDictionary *dict = [notif.userInfo objectForKey: @"args"];
    if(dict != nil)
        [LinphoneManager abstractCall:description->content dict:dict];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    UIView *dumb;
    
    // Init view descriptions
    viewDescriptions = [[NSMutableDictionary alloc] init];
    
    // Load Bars
    dumb = mainTabBarController.view;
    
    // Status Bar
    [stateBarView addSubview: stateBarController.view];
    
    //
    // Main View
    //
    PhoneViewController* myPhoneViewController = [[PhoneViewController alloc]  
                                                  initWithNibName:@"PhoneViewController" 
                                                  bundle:[NSBundle mainBundle]];
    //[myPhoneViewController loadView];
    ViewsDescription *mainViewDescription = [ViewsDescription alloc];
    mainViewDescription->content = myPhoneViewController;
    mainViewDescription->tabBar = mainTabBarController;
    mainViewDescription->statusEnabled = true;
    [viewDescriptions setObject:mainViewDescription forKey:[NSNumber numberWithInt: PhoneView_Dialer]];
    
    
    //
    // Contacts View
    //
    ContactsViewController* myContactsController = [[ContactsViewController alloc]
                                                initWithNibName:@"ContactsViewController" 
                                                bundle:[NSBundle mainBundle]];
    //[myContactsController loadView];
    ViewsDescription *contactsDescription = [ViewsDescription alloc];
    contactsDescription->content = myContactsController;
    contactsDescription->tabBar = mainTabBarController;
    contactsDescription->statusEnabled = false;
    [viewDescriptions setObject:contactsDescription forKey:[NSNumber numberWithInt: PhoneView_Contacts]];
    
    
    //
    // Call History View
    //
    HistoryViewController* myHistoryController = [[HistoryViewController alloc]
                                              initWithNibName:@"HistoryViewController" 
                                              bundle:[NSBundle mainBundle]];
    //[myHistoryController loadView];
    ViewsDescription *historyDescription = [ViewsDescription alloc];
    historyDescription->content = myHistoryController;
    historyDescription->tabBar = mainTabBarController;
    historyDescription->statusEnabled = false;
    [viewDescriptions setObject:historyDescription forKey:[NSNumber numberWithInt: PhoneView_History]];
    
    
    //
    // InCall View
    //
    InCallViewController* myInCallController = [[InCallViewController alloc]
                                                initWithNibName:@"InCallViewController" 
                                                bundle:[NSBundle mainBundle]];
    //[myHistoryController loadView];
    ViewsDescription *inCallDescription = [ViewsDescription alloc];
    inCallDescription->content = myInCallController;
    inCallDescription->tabBar = callTabBarController;
    inCallDescription->statusEnabled = false;
    [viewDescriptions setObject:inCallDescription forKey:[NSNumber numberWithInt: PhoneView_InCall]];
    
    
    // Set observer
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeView:) name:@"LinphoneMainViewChange" object:nil];
}
     
- (void)viewDidUnload {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [viewDescriptions release];
    [stateBarView release];
    [stateBarController release];
    [mainTabBarController release];
    
    [super dealloc];
}
@end