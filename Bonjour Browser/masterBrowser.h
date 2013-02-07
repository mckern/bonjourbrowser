//
//  masterBrowser.h
//  Bonjour Browser
//
//  Created by PHPdev32 on 9/5/12.
//  Licensed under GPLv3, full text at http://www.gnu.org/licenses/gpl-3.0.txt
//

@interface mdnsBrowser : NSObject <NSNetServiceBrowserDelegate>
@property NSMutableArray *children;
@property NSNetServiceBrowser *browser;
@property bool running;
@property (nonatomic) NSDictionary *txtrecord;
@property (nonatomic) NSString *name;
@property (nonatomic) bool isLeaf;
-(void)halt;
-(void)fetch;
@end

@interface masterBrowser : mdnsBrowser
+(masterBrowser *)create;
@end

@interface domainBrowser : masterBrowser
@property NSString *domain;
+(domainBrowser *)create:(NSString *)domain;
@end

@interface typeBrowser : domainBrowser
@property NSString *type;
@property NSNetService *service;
+(typeBrowser *)create:(NSNetService *)service;
@end

@interface serviceBrowser : typeBrowser <NSNetServiceDelegate>
@property bool resolved;
+(serviceBrowser *)create:(NSNetService *)service;
@end
