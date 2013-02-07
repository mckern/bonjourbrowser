//
//  AppDelegate.m
//  Bonjour Browser
//
//  Created by PHPdev32 on 9/5/12.
//  Licensed under GPLv3, full text at http://www.gnu.org/licenses/gpl-3.0.txt
//

#import "AppDelegate.h"
#import "NSObject_ServiceNames.h"

@implementation AppDelegate

@synthesize progress;
@synthesize browser;
@synthesize master;
@synthesize txtrecords;

#pragma mark Application Delegate
-(void)awakeFromNib{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults registerDefaults:@{@"tabIndex": @0, @"resolveNames": @(false)}];
    [defaults addObserver:self forKeyPath:@"tabIndex" options:0 context:nil];
    [defaults addObserver:self forKeyPath:@"resolveNames" options:0 context:nil];
}
-(void)applicationDidFinishLaunching:(NSNotification *)aNotification{
    // Insert code here to initialize your application
    assignWithNotice(self, master, [masterBrowser create])
}
-(BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender{
    return true;
}
-(void) applicationWillTerminate:(NSNotification *)notification{
    [master terminate];
}

#pragma mark Browser Delegate
-(void) browser:(NSBrowser *)sender willDisplayCell:(id)cell atRow:(NSInteger)row column:(NSInteger)column{
    //TODO: add tab-mode change
    masterBrowser *node = [self traverse:column];
    if(column==1 && [defaults boolForKey:@"resolveNames"]) [cell setStringValue:[ServiceNames resolve:node.children.allKeys[row]]];
    else [cell setStringValue:node.children.allKeys[row]];
    [cell setLeaf:(column==2)];
}
-(NSInteger) browser:(NSBrowser *)sender numberOfRowsInColumn:(NSInteger)column{
    return [[[self traverse:column] children] count];
#pragma mark Observations
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if ([keyPath isEqualToString:@"tabIndex"])
        [browser reloadColumn:0];
    else if ([keyPath isEqualToString:@"resolveNames"])
        [browser reloadColumn:1];
}

#pragma mark GUI
-(IBAction) browserChoose:(id)sender{
    if([browser selectedColumn]!=2) {
        if(self.txtrecords != nil) self.txtrecords = nil;
        return;
    }
    NSNetService *service = [(serviceBrowser *)[self traverse:3] service];
    NSMutableDictionary *records = [NSMutableDictionary dictionaryWithDictionary:@{@"_port":[NSString stringWithFormat:@"%ld",service.port],@"_addresses":[self sockArrayToString:service.addresses],@"_domain":service.domain,@"_hostName":service.hostName,@"_name":service.name,@"_type":service.type}];
    NSDictionary *txts = [NSNetService dictionaryFromTXTRecordData:service.TXTRecordData];
    for(NSString *key in txts) [records setObject:[NSString stringWithUTF8String:[(NSData *)txts[key] bytes]] forKey:key];
    self.txtrecords = [NSDictionary dictionaryWithDictionary:records];
}
#pragma mark Convenience Functions
-(masterBrowser *) traverse:(NSInteger)column{
    masterBrowser *node = master;
    int i = 0;
    while(i<column){
        node = node.children.allValues[[browser selectedRowInColumn:i]];
        i++;
    }
    return node;
}
}
@end
