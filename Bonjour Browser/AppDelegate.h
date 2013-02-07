//
//  AppDelegate.h
//  Bonjour Browser
//
//  Created by PHPdev32 on 9/5/12.
//  Licensed under GPLv3, full text at http://www.gnu.org/licenses/gpl-3.0.txt
//

#import "masterBrowser.h"

//static NSArray *titles = @[@[@"Domains",@"Types",@"Instances"],@[@"Devices",@"Types",@"Instances"]];

@interface AppDelegate : NSObject <NSApplicationDelegate,NSBrowserDelegate>
@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSProgressIndicator *progress;
@property (assign) IBOutlet NSBrowser *browser;

@property NSUserDefaults *defaults;
@property masterBrowser *master;
@property NSDictionary *txtrecords;

-(IBAction)browserChoose:(id)sender;
-(IBAction)resolve:(id)sender;
-(IBAction)tab:(id)sender;
@end