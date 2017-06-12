//
//  MasterBrowser.m
//  Bonjour Browser
//
//  Created by PHPdev32 on 9/5/12.
//  Licensed under GPLv3, full text at http://www.gnu.org/licenses/gpl-3.0.txt
//

#import "MasterBrowser.h"
#import "ServiceNames.h"

@implementation MDNSBrowser {
    @private
    NSMutableArray *_children;
}

-(instancetype)init {
    self = [super init];
    if (self && !self.isLeaf) {
        [_browser = [NSNetServiceBrowser new] setDelegate:self];
        _children = [NSMutableArray array];
    }
    return self;
}

-(void)fetch {
    if (_running)
        return;
    muteWithNotice(self, isProcessing, _processing = _running = true);
    [self browse];
}

-(void)browse {
}

-(void)halt {
    if (!_running)
        return;
    [_browser stop];
    [_children makeObjectsPerformSelector:@selector(halt)];
    _processing = _running = false;
}

-(NSDictionary *)txtrecord {
    return nil;
}

-(bool)isLeaf {
    return false;
}

-(void)setProcessing:(bool)processing {
    _processing = processing;
}

-(void)add:(MDNSBrowser *)browser {
    muteWithNotice(self, children, [_children addObject:browser]);
}

-(void)remove:(NSString *)name {
    NSUInteger i = 0;
    for (MDNSBrowser *browser in _children)
        if (++i && [browser.name isEqualToString:name]) {
            [browser halt];
            muteWithNotice(self, children, [_children removeObjectAtIndex:i - 1]);
            break;
        }
}

-(void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didNotSearch:(NSDictionary *)errorDict {
    NSString *string;
    NSInteger code = [[errorDict objectForKey:NSNetServicesErrorCode] integerValue];
    switch (code) {
        case NSNetServicesUnknownError: string = @"Unknown"; break;
        case NSNetServicesCollisionError: string = @"Collision"; break;
        case NSNetServicesNotFoundError: string = @"Not Found"; break;
        case NSNetServicesActivityInProgress: string = @"Activity In Progress"; break;
        case NSNetServicesBadArgumentError: string = @"Bad Argument"; break;
        case NSNetServicesCancelledError: string = @"Cancelled"; break;
        case NSNetServicesInvalidError: string = @"Invalid"; break;
        case NSNetServicesTimeoutError: string = @"Timeout"; break;
    }
    [NSApp performSelectorOnMainThread:@selector(presentError:) withObject:[NSError errorWithDomain:[errorDict objectForKey:NSNetServicesErrorDomain] code:code userInfo:@{NSLocalizedDescriptionKey:string ?: @""}] waitUntilDone:false];
}

-(NSArray *)children {
    return [_children sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [[obj1 name] localizedStandardCompare:[obj2 name]];
    }];
}

@end

@interface DomainBrowser ()

-(instancetype)initWithDomain:(NSString *)domain;

@end

@implementation MasterBrowser

-(void)browse {
    [self.browser searchForBrowsableDomains];
}

#pragma mark Methods
-(void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindDomain:(NSString *)domainString moreComing:(BOOL)moreComing {
    self.processing = moreComing;
    [self add:[[DomainBrowser alloc] initWithDomain:domainString]];
}

-(void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveDomain:(NSString *)domainString moreComing:(BOOL)moreComing {
    self.processing = moreComing;
    [self remove:domainString];
}
@end

@interface TypeBrowser ()

-(instancetype)initWithService:(NSNetService *)service;

@end

@implementation DomainBrowser

-(instancetype)initWithDomain:(NSString *)domain {
    self = [super init];
    if (self)
        _domain = domain;
    return self;
}

-(NSString *)name {
    return _domain;
}

-(void)browse {
    [self.browser searchForServicesOfType:@"_services._dns-sd._udp" inDomain:_domain];
}

-(void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing {
    self.processing = moreComing;
    [self add:[[TypeBrowser alloc] initWithService:aNetService]];
}

-(void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveService:(NSNetService *)aNetService moreComing:(BOOL)moreComing {
    self.processing = moreComing;
    [self remove:aNetService.name];
}

@end

@implementation TypeBrowser {
    @private
    NSString *_subtype;
}

-(instancetype)initWithService:(NSNetService *)service {
    NSArray *labels = [[NSString stringWithFormat:@"%@.%@%@",service.name,service.type,[service.domain isEqualToString:@"."] ? @"" : service.domain] componentsSeparatedByString:@"."];
    NSUInteger i = labels.count;
    self = [super initWithDomain:[[labels subarrayWithRange:NSMakeRange(i - 2, 2)] componentsJoinedByString:@"."]];
    if (self) {
        _type = [[[labels subarrayWithRange:NSMakeRange(i - 4, 2)] componentsJoinedByString:@"."] stringByAppendingString:@"."];
        _service = service;
        if (i > 4 && self.class == TypeBrowser.class)
            _subtype = [[[labels subarrayWithRange:NSMakeRange(0, i - 4)] componentsJoinedByString:@"."] stringByReplacingOccurrencesOfString:@"_" withString:@""];
    }
    return self;
}

-(NSDictionary *)txtrecord {
    return self.class == TypeBrowser.class
    ? @{@"_domain":self.domain, @"_type":_type}
    : @{@"_port":[NSString stringWithFormat:@"%ld",_service.port], @"_addresses":[SocksToStrings(_service.addresses) componentsJoinedByString:@", "], @"_domain":self.domain, @"_name":_service.name, @"_type":_type};
}

-(NSString *)name {
    NSString *type = [[_type componentsSeparatedByString:@"."] firstObject];
    type = [NSUserDefaults.standardUserDefaults boolForKey:@"resolveNames"]
    ? [ServiceNames resolve:[type substringFromIndex:1]]
    : [type substringFromIndex:1];
    return _subtype ? [NSString stringWithFormat:@"%@ (%@)", type, _subtype] : type;
}

-(void)browse {
    [self.browser searchForServicesOfType:_type inDomain:self.domain];
}

-(void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing {
    self.processing = moreComing;
    [self add:[[ServiceBrowser alloc] initWithService:aNetService]];
}

@end

@implementation ServiceBrowser

-(instancetype)initWithService:(NSNetService *)service {
    self = [super initWithService:service];
    if (self)
        [service setDelegate:self];
    return self;
}

-(NSString *)name {
    return self.service.name;
}

-(void)halt {
    [super halt];
    if (_resolved)
        [self.service stopMonitoring];
}

-(bool)isLeaf {
    return true;
}

-(void)browse {
    [self.service resolveWithTimeout:60];
}

-(NSDictionary *)txtrecord {
    if (!_resolved)
        return [super txtrecord];
    NSNetService *s = self.service;
    NSMutableDictionary *txt = [[super txtrecord] mutableCopy];
    [txt setObject:s.hostName forKey:@"_hostName"];
    NSDictionary *txts = [NSNetService dictionaryFromTXTRecordData:s.TXTRecordData];
    for (NSString *key in txts) {
        NSData *data = [txts objectForKey:key];
        [txt setObject:[[NSString alloc] initWithBytes:data.bytes length:data.length encoding:NSUTF8StringEncoding] forKey:key];
    }
    return [txt copy];
}

-(void)netServiceDidResolveAddress:(NSNetService *)sender {
    self.processing = false;
    muteWithNotice(self, txtrecord, _resolved = true);
    [self.service startMonitoring];
}

-(void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict {
    self.processing = false;
    [self netServiceBrowser:self.browser didNotSearch:errorDict];
}

-(void)netService:(NSNetService *)sender didUpdateTXTRecordData:(NSData *)data {
    muteWithNotice(self, txtrecord,);
}

@end
