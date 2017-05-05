//
//  URLManager.m
//  etracking
//
//  Created by NIKUL CHAUHAN on 4/27/16.
//  Copyright © 2016 NIKUL CHAUHAN. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "URLManager.h"
#import "JSON.h"

@implementation URLManager
@synthesize delegate;
@synthesize commandName;
@synthesize responseType;
#pragma mark -
#pragma mark Network Call Methods
#pragma mark -

- (id) init {
    self = [super init]; 
	receivedData = [[NSMutableData alloc] init];
    responseDictionary=[[NSMutableDictionary alloc] init];
    responseArray=[[NSMutableArray alloc] init];
    return self;
}

//Call the webservice at given path with the parameters in dictionary. User POST method to call webservice 
- (void)urlCall:(NSString*)path withParameters:(NSMutableDictionary*)dictionary {
	NSString * urlStr = [NSString stringWithFormat:@"%@",path];
	NSMutableURLRequest *theRequest = [[[NSMutableURLRequest alloc] init] autorelease];
	
	[theRequest setURL:[NSURL URLWithString:urlStr]];
	if (dictionary!=nil) 
    {
		NSString *requestStr = [self postStringFromDictionary:dictionary];
		NSData *requestData = [requestStr dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
		NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[requestData length]];
		[theRequest setValue:postLength forHTTPHeaderField:@"Content-Length"];
		[theRequest setHTTPBody:requestData];
	}
	
	[theRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
	[theRequest setHTTPMethod:@"POST"];
	[theRequest setHTTPShouldHandleCookies:NO];
	
	NSURLConnection *theConnection = [[[NSURLConnection alloc] initWithRequest:theRequest delegate:self] autorelease];
	if (theConnection) {
		//If hadle the condition.
	}
}

- (void)urlCall:(NSString*)path withJSONString:(NSString *)jsonString {
    NSString * urlStr = [NSString stringWithFormat:@"%@",path];
    NSMutableURLRequest *theRequest = [[[NSMutableURLRequest alloc] init] autorelease];
    
    [theRequest setURL:[NSURL URLWithString:urlStr]];
//    if (dictionary!=nil)
//    {
//        NSString *requestStr = [self postStringFromDictionary:dictionary];
//        NSData *requestData = [requestStr dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
//        NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[requestData length]];
//        [theRequest setValue:postLength forHTTPHeaderField:@"Content-Length"];
//        [theRequest setHTTPBody:requestData];
//    }

    NSData *requestData = [jsonString dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[requestData length]];
    [theRequest setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [theRequest setHTTPBody:requestData];

    
    [theRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [theRequest setHTTPMethod:@"POST"];
    [theRequest setHTTPShouldHandleCookies:NO];
    
    NSURLConnection *theConnection = [[[NSURLConnection alloc] initWithRequest:theRequest delegate:self] autorelease];
    if (theConnection) {
        //If hadle the condition.
    }
}


//Call the webservice at given path with the parameters in dictionary. User GET method to call webservice 
- (void)urlCallGetMethod:(NSString*)path withParameters:(NSMutableDictionary*)dictionary {
	NSMutableURLRequest *theRequest = [[[NSMutableURLRequest alloc] init] autorelease];
	NSString *urlStr = @"";
	if (dictionary!=nil) {
		NSString *requestStr = [self postStringFromDictionary:dictionary];
		urlStr = [NSString stringWithFormat:@"%@?%@",path,requestStr];
        urlStr = [urlStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	}
	else {
		urlStr = path;
	}
	NSLog(@"Request : %@",urlStr);
	[theRequest setURL:[NSURL URLWithString:urlStr]];
	[theRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
	[theRequest setHTTPMethod:@"GET"];
	[theRequest setHTTPShouldHandleCookies:NO];
	
	NSURLConnection *theConnection= [[[NSURLConnection alloc] initWithRequest:theRequest delegate:self] autorelease];
	if (theConnection) {
		//If hadle the condition.
	}
}

//Return a parameter string from the dictionary  
- (NSString *)postStringFromDictionary:(NSMutableDictionary*)dictionary {
	NSString *argumentStr = @"";
	for (int i=0 ; i<[[dictionary allKeys] count]; i++)  {
		if ( i != 0) 
			argumentStr = [argumentStr stringByAppendingString:@"&"];

		NSString *key = [[dictionary allKeys] objectAtIndex:i];
		NSString *value = [dictionary objectForKey:key];
		NSString *formateStr = [NSString stringWithFormat:@"%@=%@",key,value];
		argumentStr = [argumentStr stringByAppendingString:formateStr];
	}
	NSLog(@"%@ \n-------------------\n",argumentStr);
	return argumentStr;
}

#pragma mark -
#pragma mark NSURLConnection Methods
#pragma mark -

//This method is called when the URL loading system has received sufficient load data to construct 
//a NSURLResponse object.
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    [receivedData setLength:0];
}

//This method is called to deliver the content of a URL load.
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [receivedData appendData:data];
}
// This method is called when an NSURLConnection has failed to load successfully.
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
   // [connection release];
	[receivedData release];
   NSLog(@"Connection failed! Error - %@ %@", [error localizedDescription],
          [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]);
	[delegate onError:error];
}

//This method is called when an NSURLConnection has finished loading successfully.
- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	//[connection release];
	
	NSString *responseString = [[NSString alloc] initWithData:receivedData encoding:NSUTF8StringEncoding];
	[receivedData release];
	NSLog(@"The response is... %@", responseString);
	if (responseString == nil ) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Alert!" message:@"No responce from server"
													  delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert show];
		[alert release];
	}
	else if (commandName!=nil && commandName!=NULL) {
		NSMutableDictionary *result = [[NSMutableDictionary alloc] init];

			if (responseType == JSON_TYPE) {
				NSError *error; 
				SBJSON *json = [[SBJSON new] autorelease];
				NSDictionary *response = [json objectWithString:responseString error:&error];
				if (response != nil ) {
					[result setObject:response forKey:@"result"];
				}
			}
			else
            {
//				[result setObject:responseString forKey:@"result"];
                
                if(commandName)
                {
                    responseString=[responseString stringByReplacingOccurrencesOfString:@"&lt;" withString:@"<"];
                    responseString=[responseString stringByReplacingOccurrencesOfString:@"&gt;" withString:@">"];
                    
                    NSLog(@"Now response :- %@",responseString);
                    
                    //UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Response" message:responseString delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil];
                    //[alert show];
                    
                    NSXMLParser *parser=[[NSXMLParser alloc] initWithData:[responseString dataUsingEncoding:NSUTF8StringEncoding]];
                    parser.delegate=self;
                    [parser parse];
                }
			}
			[result setObject:commandName forKey:@"commandName"];
            
			[delegate onResult:result];
			[result release];
	}
	[responseString release];
}

-(void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    
    [responseDictionary setValue:currentElementValue forKey:elementName];
    NSLog(@"Element Name : %@",elementName);
    if ([elementName isEqualToString:@"distance"])
    {
        [responseArray addObject:[responseDictionary mutableCopy]];
    }
    currentElementValue=nil;
}
- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    if(!currentElementValue)
        currentElementValue = [[NSMutableString alloc] initWithString:string];
    else
        [currentElementValue appendString:string];
}

- (void)parserDidEndDocument:(NSXMLParser *)parser
{
    if([[[responseDictionary valueForKey:@"Status"] lowercaseString] isEqualToString:@"false"])
    {
        NSError *error=nil;
        if(!([commandName isEqualToString:@"IsAuthenticatedUser"] || [commandName isEqualToString:@"IsAuthenticatedUserForced"] ))
            [delegate onError:error];
        else
        {
            NSMutableDictionary *response=[[NSMutableDictionary alloc] init];
            [response setValue:responseArray forKey:@"result"];
            [response setValue:commandName forKey:@"command"];
            NSLog(@"Response:%@",response);
            [delegate onResult:response];
        }
    }
    else
    {
        NSMutableDictionary *response=[[NSMutableDictionary alloc] init];
        [response setValue:responseArray forKey:@"result"];
        [response setValue:commandName forKey:@"command"];
        NSLog(@"RResponse:%@",response);
        NSLog(@"Delegate : %@",delegate);
        [delegate onResult:response];
        //[responseDictionary release];
        //responseDictionary=nil;
    }
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError
{
    NSError *error=nil;
    [delegate onError:error];
}

#pragma mark -
#pragma mark Cleanup Methods
#pragma mark -

- (void) dealloc {
	[commandName release];
	[super dealloc];
}

@end
