//
//  ServiceNames.h
//  Bonjour Browser
//
//  Created by PHPdev32 on 1/29/14.
//  Licensed under GPLv3, full text at http://www.gnu.org/licenses/gpl-3.0.txt
//

#import <Foundation/Foundation.h>

NSArray* SocksToStrings(NSArray *addresses);

@interface ServiceNames : NSObject

+(NSString *)resolve:(NSString *)service;

@end
