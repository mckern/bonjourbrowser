//
//  masterBrowser.m
//  Bonjour Browser
//
//  Created by PHPdev32 on 9/5/12.
//  Licensed under GPLv3, full text at http://www.gnu.org/licenses/gpl-3.0.txt
//

#import "masterBrowser.h"
#import "NSObject_ServiceNames.h"

@implementation mdnsBrowser
@synthesize children;
@synthesize running;
@synthesize browser;

+(void)progress:(bool)animates{
    [[NSApp delegate] setAnimates:animates];
}

-(id)init{
    self = [super init];
    if (self) {
        browser = [NSNetServiceBrowser new];
        children = [NSMutableArray array];
        [browser setDelegate:self];
        running = false;
    }
    return self;
}
-(void)fetch{
    if (running) return;
    [self browse];
    [mdnsBrowser progress:true];
    running = true;
}
-(void)browse{
}
-(void)halt{
    for(masterBrowser *browse in children)
        [browse halt];
    [browser stop];
}
-(NSDictionary *)txtrecord{
    return @{};
}
-(bool)isLeaf{
    return false;
}
-(void)remove:(NSString *)name{
    NSUInteger i = [[children valueForKey:@"name"] indexOfObject:name];
    [[children objectAtIndex:i] halt];
    muteWithNotice(self, children, [children removeObjectAtIndex:i])
}
-(void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didNotSearch:(NSDictionary *)errorDict{
    ModalNSNetError(errorDict);
}

@end

@implementation masterBrowser

+(masterBrowser *)create{
    masterBrowser *temp = [masterBrowser new];
    [temp fetch];
    return temp;
}
-(void)browse{
    [self.browser searchForBrowsableDomains];
}

#pragma mark Methods
-(void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindDomain:(NSString *)domainString moreComing:(BOOL)moreComing{
    if (!moreComing) [mdnsBrowser progress:false];
    muteWithNotice(self, children, [self.children addObject:[domainBrowser create:domainString]])
}
-(void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveDomain:(NSString *)domainString moreComing:(BOOL)moreComing{
    [self remove:domainString];
}
@end
@implementation domainBrowser
@synthesize domain;
+(domainBrowser *)create:domain{
    domainBrowser *temp = [domainBrowser new];
    temp.domain = domain;
    return temp;
}
-(NSString *)name{
    return domain;
}
-(void)browse {
    [self.browser searchForServicesOfType:@"_services._dns-sd._udp" inDomain:domain];
}
-(void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing{
    if (!moreComing) [mdnsBrowser progress:false];
    muteWithNotice(self, children, [self.children addObject:[typeBrowser create:aNetService]])
}
-(void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveService:(NSNetService *)aNetService moreComing:(BOOL)moreComing{
    if (!moreComing) [mdnsBrowser progress:false];
    [self remove:aNetService.name];
}
@end

@implementation typeBrowser

@synthesize type;
@synthesize service;

+(typeBrowser *)create:(NSNetService *)service{
    NSMutableArray *parts = [NSMutableArray arrayWithArray:[[NSString stringWithFormat:@"%@%@%@",service.name,service.domain,service.type] componentsSeparatedByString:@"."]];
    [parts insertObject:@"" atIndex:2];
    typeBrowser *temp = [typeBrowser new];
    temp.type = [[parts subarrayWithRange:NSMakeRange(0, 3)] componentsJoinedByString:@"."];
    temp.domain = [[parts subarrayWithRange:NSMakeRange(3, parts.count-3)] componentsJoinedByString:@"."];
    temp.service = service;
    return temp;
}
-(NSDictionary *)txtrecord{
    return @{@"_port":[NSString stringWithFormat:@"%ld",service.port], @"_addresses":[SocksToStrings(service.addresses) componentsJoinedByString:@", "], @"_domain":service.domain, @"_name":service.name, @"_type":service.type};
}
-(NSString *)name{
    return ([NSUserDefaults.standardUserDefaults boolForKey:@"resolveNames"])?[ServiceNames resolve:[self.service.name substringFromIndex:1]]:[self.service.name substringFromIndex:1];
}
-(void)browse{
    [self.browser searchForServicesOfType:type inDomain:self.domain];
}
-(void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing{
    if (!moreComing) [mdnsBrowser progress:false];
    muteWithNotice(self, children, [self.children addObject:[serviceBrowser create:aNetService]])
}
@end

@implementation serviceBrowser
@synthesize resolved;

+(serviceBrowser *)create:(NSNetService *)service{
    serviceBrowser *temp = [serviceBrowser new];
    temp.service = service;
    temp.resolved = false;
    [temp.service setDelegate:temp];
    return temp;
}
-(NSString *)name{
    return self.service.name;
}
-(void)halt{
    [super halt];
    if (resolved) [self.service stopMonitoring];
}
-(bool)isLeaf{
    return true;
}
-(void)browse{
    [self.service resolveWithTimeout:10.0];
}
-(NSDictionary *)txtrecord{
    if (!resolved) return @{};
    NSMutableDictionary *txt = [NSMutableDictionary dictionaryWithDictionary:[super txtrecord]];
    [txt setObject:self.service.hostName forKey:@"_hostName"];
    NSDictionary *txts = [NSNetService dictionaryFromTXTRecordData:self.service.TXTRecordData];
    for(NSString *key in txts)
        [txt setObject:NSStringForData([txts objectForKey:key], NSASCIIStringEncoding) forKey:key];
    return [NSDictionary dictionaryWithDictionary:txt];
}
-(void)netServiceDidResolveAddress:(NSNetService *)sender{
    [mdnsBrowser progress:false];
    self.resolved = true;
    muteWithNotice(self, txtrecord, )
    [self.service startMonitoring];
}
-(void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict{
    [mdnsBrowser progress:false];
    ModalNSNetError(errorDict);
}
-(void)netService:(NSNetService *)sender didUpdateTXTRecordData:(NSData *)data{
    muteWithNotice(self, txtrecord, )
}
@end