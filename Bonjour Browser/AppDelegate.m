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
@synthesize defaults;
@synthesize txtrecords;

#pragma mark Application Delegate
-(void) awakeFromNib{
    defaults = [NSUserDefaults standardUserDefaults];
    [defaults registerDefaults:@{@"tabIndex":@0,@"resolveNames":@NO}];
    master = [masterBrowser create];
}
-(void) applicationDidFinishLaunching:(NSNotification *)aNotification{
    // Insert code here to initialize your application
}
-(BOOL) applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender{
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
-(IBAction) resolve:(id)sender{
    [browser reloadColumn:1];
}
-(IBAction) tab:(id)sender{
    [browser reloadColumn:0];
    //TODO: column titles
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
-(NSString *)sockArrayToString:(NSArray *)addresses{
    NSMutableArray *temp = [NSMutableArray array];
    for(NSData *addr in addresses) {
        NSString *str = [NSString string];
        switch (((struct sockaddr *)[addr bytes])->sa_family) {
            case AF_INET:{
                struct sockaddr_in *sock = (struct sockaddr_in *)[addr bytes];
                char ad[INET_ADDRSTRLEN];
                inet_ntop(AF_INET, &sock->sin_addr, ad, INET_ADDRSTRLEN);
                str = [NSString stringWithFormat:@"%s:%u",ad,ntohs(sock->sin_port)];
                break;
            }
            case AF_INET6:{
                struct sockaddr_in6 *sock = (struct sockaddr_in6 *)[addr bytes];
                char ad[INET6_ADDRSTRLEN];
                inet_ntop(AF_INET6, &sock->sin6_addr, ad, INET6_ADDRSTRLEN);
                str = [NSString stringWithFormat:@"%s@%u",ad,ntohs(sock->sin6_port)];
                break;
            }
            case AF_LINK:{
                struct sockaddr_dl *sock = (struct sockaddr_dl *)[addr bytes];
                char *name = NULL;
                char *ll = NULL;
                strlcpy(name, sock->sdl_data, sock->sdl_nlen);
                strlcpy(ll, sock->sdl_data+sock->sdl_nlen, sock->sdl_alen);
                str = [NSString stringWithFormat:@"%s %s",name,ll];
                break;
            }
        }
        [temp addObject:str];
    }
    return [temp componentsJoinedByString:@", "];
}
@end