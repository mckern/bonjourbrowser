//
//  masterBrowser.m
//  Bonjour Browser
//
//  Created by PHPdev32 on 9/5/12.
//  Licensed under GPLv3, full text at http://www.gnu.org/licenses/gpl-3.0.txt
//

#import "masterBrowser.h"
#import "AppDelegate.h"

@implementation masterBrowser
@synthesize children;
@synthesize browser;
+(masterBrowser *) create{
    masterBrowser *temp = [masterBrowser new];
    temp.children = [NSMutableDictionary dictionary];
    temp.browser = [NSNetServiceBrowser new];
    [temp.browser setDelegate:temp];
    [temp.browser searchForBrowsableDomains];
    return temp;
}
-(void) terminate{
    if(children!=nil) for(NSString *browse in children) [(masterBrowser *)children[browse] terminate];
    [browser stop];
}
-(void) netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindDomain:(NSString *)domainString moreComing:(BOOL)moreComing{
    if(children[domainString] != nil) return;
    [children setObject:[domainBrowser create:aNetServiceBrowser withDomain:domainString] forKey:domainString];
    [(NSBrowser *)[[NSApp delegate] browser] reloadColumn:0];
}
-(void) netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveDomain:(NSString *)domainString moreComing:(BOOL)moreComing{
    [(domainBrowser *)children[domainString] terminate];
    [children removeObjectForKey:domainString];
}
-(void) netServiceBrowserWillSearch:(NSNetServiceBrowser *)aNetServiceBrowser{
    [[[NSApp delegate] progress] startAnimation:self];
}
-(void) netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)aNetServiceBrowser{
    [[[NSApp delegate] progress] stopAnimation:self];
}
-(void) netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didNotSearch:(NSDictionary *)errorDict{
    [NSAlert alertWithError:[NSError errorWithDomain:errorDict[NSNetServicesErrorDomain] code:[errorDict[NSNetServicesErrorCode] longValue] userInfo:errorDict]];
}
@end
@implementation domainBrowser
+(domainBrowser *)create:(NSNetServiceBrowser *)browser withDomain:(NSString *)domain{
    domainBrowser *temp = [domainBrowser new];
    temp.children = [NSMutableDictionary dictionary];
    temp.browser = [NSNetServiceBrowser new];
    [temp.browser setDelegate:temp];
    [temp.browser searchForServicesOfType:@"_services._dns-sd._udp" inDomain:domain];
    return temp;
}
-(void) netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing{
    if(self.children[aNetService.name]!=nil) return;
    [self.children setObject:[typeBrowser create:aNetServiceBrowser withService:aNetService] forKey:[aNetService.name substringFromIndex:1]];
    [[[NSApp delegate] progress] stopAnimation:self];
}
-(void) netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveService:(NSNetService *)aNetService moreComing:(BOOL)moreComing{
    [(typeBrowser *)self.children[aNetService.name] terminate];
    [self.children removeObjectForKey:aNetService.name];
}
@end
@implementation typeBrowser
@synthesize service;
+(typeBrowser *)create:(NSNetServiceBrowser *)browser withService:(NSNetService *)service{
    NSMutableArray *parts = [NSMutableArray arrayWithArray:[[NSString stringWithFormat:@"%@%@%@",service.name,service.domain,service.type] componentsSeparatedByString:@"."]];
    [parts insertObject:@"" atIndex:2];
    NSString *type = [[parts subarrayWithRange:(NSRange){0,3}] componentsJoinedByString:@"."];
    NSString *domain = [[parts subarrayWithRange:(NSRange){3,[parts count]-3}] componentsJoinedByString:@"."];
    typeBrowser *temp = [typeBrowser new];
    temp.children = [NSMutableDictionary dictionary];
    temp.browser = [NSNetServiceBrowser new];
    temp.service = service;
    [temp.browser setDelegate:temp];
    [temp.browser searchForServicesOfType:type inDomain:domain];
    return temp;
}
-(void) netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing{
    if(self.children[aNetService.name]!=nil) return;
    [self.children setObject:[serviceBrowser create:aNetServiceBrowser withService:aNetService] forKey:aNetService.name];
}
-(void) netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveService:(NSNetService *)aNetService moreComing:(BOOL)moreComing{
    [(serviceBrowser *)self.children[aNetService.name] terminate];
    [self.children removeObjectForKey:aNetService.name];
}
@end
@implementation serviceBrowser
@synthesize resolved;
+(serviceBrowser *)create:(NSNetServiceBrowser *)browser withService:(NSNetService *)service{
    serviceBrowser *temp = [serviceBrowser new];
    temp.children = [NSMutableDictionary dictionary];
    temp.service = service;
    [temp.service setDelegate:temp];
    [temp.service resolveWithTimeout:10.0];
    return temp;
}
-(void) netServiceDidResolveAddress:(NSNetService *)sender{
    self.resolved = true;
}
-(void) netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict{
    self.resolved = false;
    [NSAlert alertWithError:[NSError errorWithDomain:errorDict[NSNetServicesErrorDomain] code:[errorDict[NSNetServicesErrorCode] longValue] userInfo:errorDict]];
}
-(void) terminate{
    [self.service stop];
}
@end