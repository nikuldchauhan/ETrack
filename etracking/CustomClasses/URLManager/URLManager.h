//
//  URLManager.h
//  etracking
//
//  Created by NIKUL CHAUHAN on 4/27/16.
//  Copyright © 2016 NIKUL CHAUHAN. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol URLManagerDelegate

- (void)onResult:(NSDictionary *)result;
- (void)onError:(NSError *)error;

@end
enum RESPONSE_TYPE {
	XML_TYPE = 0,
	JSON_TYPE
};


@interface URLManager : NSObject <NSXMLParserDelegate> {
	NSMutableData *receivedData;
	id<URLManagerDelegate> delegate;
	NSString *commandName;
    NSMutableString *currentElementValue;
    NSMutableArray *responseArray;
    NSMutableDictionary *responseDictionary;
	enum RESPONSE_TYPE responseType;
}

@property (assign) id<URLManagerDelegate> delegate;
@property (nonatomic, retain) NSString *commandName;
@property (nonatomic, assign) enum RESPONSE_TYPE responseType;


- (void)urlCall:(NSString*)path withParameters:(NSMutableDictionary*)dictionary;
- (NSString *)postStringFromDictionary:(NSMutableDictionary*)dictionary;
- (void)urlCallGetMethod:(NSString*)path withParameters:(NSMutableDictionary*)dictionary;
- (void)urlCall:(NSString*)path withJSONString:(NSString *)jsonString;

@end
