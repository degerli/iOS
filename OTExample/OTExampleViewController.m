//
//  OTExampleViewController.m
//  OTExample
//
//  Created by Pavitra on 10/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "OTExampleViewController.h"
#import "OTLogService.h"
@implementation OTExampleViewController

@synthesize sliderLabel;


-(IBAction)clickedButton:(id)sender {
    NSLog(@"clickedButton");
   [[OTLogService sharedOTLogService] sendEvent:@"button clicked" ];
}
-(IBAction)switchMoved:(id)sender{
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init ];
    [dictionary setObject:@"switch changed" forKey:@"title"];
    [dictionary setObject:[[NSString alloc] initWithFormat:@"%@", [sender isOn] ? @"ON":@"OFF" ] forKey:@"custom defined switch value"];
    [[OTLogService sharedOTLogService]  sendEvent:dictionary ];
    [dictionary release];
}

-(IBAction) sliderChanged:(id) sender{
    UISlider *slider = (UISlider *) sender;
    int progressAsInt =(int)(slider.value);
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init ];
    [dictionary setObject:@"slider moved" forKey:@"title"];
    [dictionary setObject:[[NSString alloc] initWithFormat:@"%d", progressAsInt ] forKey:@"custom defined slider value"];
    [[OTLogService sharedOTLogService]  sendEvent:dictionary ];
    [dictionary release];
}


- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}



#pragma mark - View lifecycle

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
}
*/

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
