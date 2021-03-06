//
//  OTSend.m
//  opentracker
//
//  Created by Pavitra on 9/29/11.
//  Copyright 2011 Opentracker. All rights reserved.
//

#import "OTSend.h"
#import "OTFileUtils.h"


@implementation OTSend

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}
#pragma mark Send Url
/*
 Sends the URL request as a synchronous HTTP Request.
 If successful then it returns the response in string else returns nil.
 */

+(NSString*) sendUrl: (NSString*) url {
    
	//Create and return an initialized URL request with specified url.
    NSURLRequest *theRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:url]
                                                cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
    NSHTTPURLResponse *response = nil;     
    NSString *responseDataString;     
    @try {
        //Perform a synchronous load of the specified URL request
        NSData *responseData = [NSURLConnection sendSynchronousRequest:theRequest returningResponse: &response error:nil];
        //Gets the NSData content in NSString format. 
        responseDataString = [[NSString alloc] initWithData:responseData encoding:NSASCIIStringEncoding];
    }
    @catch (NSException *exception) {
        NSLog(@"sendUrl: url, connection failed");
        responseDataString = nil;
    }
    
	return responseDataString;
}
#pragma mark Send
/*
 Sends the URL Request with the key values of the dictionary as HTTP Request
 On Success returns the response as string
 
 
 */

+(void) send: (NSMutableDictionary*) keyValuePairs {
    NSLog(@"send:keyValuePairs %@",keyValuePairs);
    NSString* url = @"http://log.opentracker.net/?";
    for (id key in keyValuePairs) {
		//NSLog(@"key is %@",(NSString*)key);
        NSString *value = [keyValuePairs objectForKey:key];
        url = [NSString stringWithFormat:@"%@%@=%@&", url, [self urlEncoded:key] , [self urlEncoded:value]];     		
	}
    
    NSString *responseDataString =nil;
    //if any error encountered on request object
    //NSString* encodedData = [self urlEncoding];
     [NSThread detachNewThreadSelector:@selector(sendNewThread:) toTarget:self withObject:url]; 
}

+(void) sendNewThread : (NSString*) url { 
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    //add a background task , when/if the application is moved to the background when data is being uploaded
    UIBackgroundTaskIdentifier *bgtask = nil;
    UIApplication *app = [UIApplication sharedApplication];
    bgtask = [app beginBackgroundTaskWithExpirationHandler:^{}];
    //Create and return an initialized URL request with the specified url.
    NSURLRequest *theRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:url]
                                                cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
    NSHTTPURLResponse *response = nil;
    
    NSString *responseDataString =nil;
    BOOL isSuccessful = NO;
    NSError *error = nil;
    @try {
        //Perform a synchronous load of the specified URL request
        NSData *responseData = [NSURLConnection sendSynchronousRequest:theRequest returningResponse: &response error:&error];
        //Gets the NSData content in NSString format. 
        responseDataString = [[NSString alloc] initWithData:responseData encoding:NSASCIIStringEncoding];
        isSuccessful = YES;
    }
    @catch (NSException *exception) {
        NSLog(@"send: keyValuePairs, connection failed.Exception thrown.");
        responseDataString = nil;
        isSuccessful = NO;
    }
    if (error) {
        NSLog(@"send: keyValuePairs, connection failed");
        responseDataString = nil;
        isSuccessful = NO;
    }
    [pool release];
    [app endBackgroundTask:bgtask];
    bgtask = UIBackgroundTaskInvalid;
}

+(void) uploadFileNewThread :(NSString*) fileToSend {
    [NSThread detachNewThreadSelector:@selector(uploadFile:) toTarget:self withObject:fileToSend];
}

#pragma mark Upload File
/*
 Uploads the specified file to the specified server
 Deletes zipped file and file before zip if successful.
 */

+(void) uploadFile:(NSString*) fileToSend {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    //see: http://developer.apple.com/library/mac/#documentation/Cocoa/Conceptual/ObjectiveC/Chapters/ocThreading.html#//apple_ref/doc/uid/TP30001163-CH19-SW1
    @synchronized(self){
        NSLog(@"uploadFile");
        UIBackgroundTaskIdentifier *bgtask = nil;
        UIApplication *app = [UIApplication sharedApplication];
        bgtask = [app beginBackgroundTaskWithExpirationHandler:^{}];
        NSString* newFileName = [NSString stringWithFormat:@"%@.%@.gz",[fileToSend stringByReplacingOccurrencesOfString:@".gz" withString:@""], [self UUID]];
        NSLog(@"new filename: %@", newFileName);
        //string data
        // see uploading file : http://stackoverflow.com/questions/2229002/how-to-send-file-along-some-post-variables-with-objective-c-iphone-sdk
        NSString *post = @"message=test";
        NSData *postData = [post dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
        
        //file data
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *fullPathToFile = [documentsDirectory stringByAppendingPathComponent:fileToSend];
        NSData *dataToPost = [[NSData alloc] initWithContentsOfFile:fullPathToFile];
        //NSLog(@"data to post:%@", dataToPost);
        
        //request
        NSString *url = @"http://upload.opentracker.net/upload/upload.jsp";
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
        NSHTTPURLResponse *response = nil;
        [request setHTTPMethod:@"POST"];
        NSString *boundary = @"*****";
        NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
        [request addValue:contentType forHTTPHeaderField: @"Content-Type"];
        
        //POST body
        NSMutableData *postbody = [NSMutableData data]; 
        
        //append string data
        [postbody appendData:postData];
        
        //append file
        [postbody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        NSString *contentWithFilename = [NSString stringWithFormat:@"Content-Disposition: form-data; name=\"file\"; filename=\"%@\"\r\n", newFileName  ] ;
        [postbody appendData:[[NSString stringWithString:contentWithFilename] dataUsingEncoding:NSUTF8StringEncoding]];
        
        [postbody appendData:[[NSString stringWithString:@"Content-Type: application/octet-stream\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
        [postbody appendData:[NSData dataWithData:dataToPost]];
        [postbody appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        
        [request setHTTPBody:postbody];
        
        //set content length
        NSString *postLength = [NSString stringWithFormat:@"%d", [postbody length]];
        [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
        
        //send and receive
        NSString *responseDataString = nil;
        BOOL isSuccessful = NO; 
        NSError *error = nil;
        @try {
            NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
            responseDataString = [[NSString alloc] initWithData:responseData encoding:NSASCIIStringEncoding];
            isSuccessful = YES;
        }
        @catch (NSException *exception) {
            NSLog(@"connection failed.Exception thrown.");
            
            responseDataString = nil;
            isSuccessful = NO;
        }
        
        //if error is encountered on upload
        if (error) {
            NSLog(@"connection failed");
            responseDataString = nil;
            isSuccessful = NO;
        }
        
        if (isSuccessful) {
            //NSLog(@"The response : %@", response);
            [OTFileUtils removeFile:fileToSend];
            [OTFileUtils removeFile:@"fileToSend"];
            NSLog(@"cleared files");
        } else {
            NSLog(@"File did not empty!");
            [OTFileUtils removeFile:fileToSend];
        }
        //before we upload the data, wait for five seconds
        double t0 = [[NSDate date] timeIntervalSince1970];
        [NSThread sleepForTimeInterval:5.0];
        NSLog(@"time sleep:%.2f", [[NSDate date] timeIntervalSince1970] - t0 );
        [pool release];
        [app endBackgroundTask:bgtask];
        bgtask = UIBackgroundTaskInvalid;
    }
}
#pragma mark URL Encoded
/*
 This function will encode the given string. 
 Converts the special characters to web characters
 */

+(NSString*) urlEncoded : (NSString*) url{
    CFStringRef urlString = CFURLCreateStringByAddingPercentEscapes(
                                                                    NULL,
                                                                    (CFStringRef)url,
                                                                    NULL,
                                                                    (CFStringRef)@"!*'\"();:@&=+$,/?%#[]% ",
                                                                    kCFStringEncodingUTF8 );
	return [(NSString *)urlString autorelease];
}

#pragma mark UUID
/*
 This function is used to get the device UUID - Universal Unique Identifier
 */

+(NSString*) UUID{
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, theUUID);
    CFRelease(theUUID);	
    return [(NSString *)string autorelease];
}    

@end
