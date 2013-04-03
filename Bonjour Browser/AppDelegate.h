//
//  AppDelegate.h
//  Bonjour Browser
//
//  Created by PHPdev32 on 9/5/12.
//  Licensed under GPLv3, full text at http://www.gnu.org/licenses/gpl-3.0.txt
//

#import "masterBrowser.h"

@interface AppDelegate : NSObject <NSApplicationDelegate>
@property (assign) IBOutlet NSBrowser *browser;

@property masterBrowser *master;
@property bool animates;

-(IBAction)choose:(id)sender;
@end
