//
//  masterBrowser.h
//  Bonjour Browser
//
//  Created by PHPdev32 on 9/5/12.
//  Licensed under GPLv3, full text at http://www.gnu.org/licenses/gpl-3.0.txt
//

@interface masterBrowser : NSObject <NSNetServiceBrowserDelegate>
@property NSMutableDictionary *children;
@property NSNetServiceBrowser *browser;
+(masterBrowser *)create;
-(void) terminate;
-(void) netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindDomain:(NSString *)domainString moreComing:(BOOL)moreComing;
-(void) netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveDomain:(NSString *)domainString moreComing:(BOOL)moreComing;
-(void) netServiceBrowserWillSearch:(NSNetServiceBrowser *)aNetServiceBrowser;
-(void) netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)aNetServiceBrowser;
-(void) netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didNotSearch:(NSDictionary *)errorDict;
@end

@interface domainBrowser : masterBrowser
+(domainBrowser *)create:(NSNetServiceBrowser *)browser withDomain:(NSString *)domain;
-(void) netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing;
-(void) netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveService:(NSNetService *)aNetService moreComing:(BOOL)moreComing;
@end

@interface typeBrowser : domainBrowser
@property NSNetService *service;
+(typeBrowser *)create:(NSNetServiceBrowser *)browser withService:(NSNetService *)service;
@end

@interface serviceBrowser : typeBrowser <NSNetServiceDelegate>
@property bool resolved;
+(serviceBrowser *)create:(NSNetServiceBrowser *)browser withService:(NSNetService *)service;
-(void) netServiceDidResolveAddress:(NSNetService *)sender;
-(void) netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict;
-(void) terminate;
@end
