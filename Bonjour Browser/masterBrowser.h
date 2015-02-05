//
//  masterBrowser.h
//  Bonjour Browser
//
//  Created by PHPdev32 on 9/5/12.
//  Licensed under GPLv3, full text at http://www.gnu.org/licenses/gpl-3.0.txt
//

@interface mdnsBrowser : NSObject <NSNetServiceBrowserDelegate>

@property (readonly) NSArray *children;
@property (readonly) NSNetServiceBrowser *browser;
@property (readonly, getter = isRunning) bool running;
@property (readonly) NSDictionary *txtrecord;
@property (readonly) NSString *name;
@property (readonly, getter = isLeaf) bool leaf;
@property (readonly, getter = isProcessing) bool processing;

-(void)halt;
-(void)fetch;

@end

@interface masterBrowser : mdnsBrowser

@end

@interface domainBrowser : masterBrowser

@property (readonly) NSString *domain;

@end

@interface typeBrowser : domainBrowser

@property (readonly) NSString *type;
@property (readonly) NSNetService *service;

@end

@interface serviceBrowser : typeBrowser <NSNetServiceDelegate>

@property (readonly, getter = didResolve) bool resolved;

@end
