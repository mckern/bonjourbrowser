//
//  AppDelegate.m
//  Bonjour Browser
//
//  Created by PHPdev32 on 9/5/12.
//  Licensed under GPLv3, full text at http://www.gnu.org/licenses/gpl-3.0.txt
//

#import "AppDelegate.h"

@implementation AppDelegate

@synthesize browser;
@synthesize master;

#pragma mark Application Delegate
-(void)awakeFromNib{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults registerDefaults:@{@"tabIndex": @0, @"resolveNames": @(false)}];
    [defaults addObserver:self forKeyPath:@"tabIndex" options:0 context:nil];
    [defaults addObserver:self forKeyPath:@"resolveNames" options:0 context:nil];
}
-(void)applicationDidFinishLaunching:(NSNotification *)aNotification{
    // Insert code here to initialize your application
    self.master = [masterBrowser create];
}
-(BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender{
    return true;
}
-(void)applicationWillTerminate:(NSNotification *)notification{
    [master halt];
}

#pragma mark Observations
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if ([keyPath isEqualToString:@"tabIndex"])
        [browser reloadColumn:0];
    else if ([keyPath isEqualToString:@"resolveNames"])
        [browser reloadColumn:1];
}

#pragma mark GUI
-(IBAction)choose:(id)sender{
    [[[[sender selectedCell] representedObject] representedObject] fetch];
}
@end
