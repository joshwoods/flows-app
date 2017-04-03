//
//  AddStationViewController.m
//  newFlows
//
//  Created by Matt Riddoch on 9/25/15.
//  Copyright © 2015 Matt Riddoch. All rights reserved.
//

#import "InfoViewController.h"
//#import "GDIIndexBar.h"
//#import "AddDetailViewController.h"
#import "UIColor+Hexadecimal.h"
//#import "iRate.h"
#import <MessageUI/MessageUI.h>
#import <QuartzCore/QuartzCore.h>
#import "infoCell.h"


@interface InfoViewController () <MFMailComposeViewControllerDelegate, UITableViewDelegate, UITableViewDataSource >

@property (weak, nonatomic) IBOutlet UITableView *mainTable;
@property (weak, nonatomic) IBOutlet UIView *highView;
@property (weak, nonatomic) IBOutlet UIView *normalView;
@property (weak, nonatomic) IBOutlet UIView *lowView;

@end

@implementation InfoViewController{
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new]
                                                  forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = [UIImage new];
    self.navigationController.navigationBar.translucent = YES;
    
    UIImageView* img = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"HeaderLogo"]];
    self.navigationItem.titleView = img;
    
    [self.mainTable setSeparatorColor:[UIColor colorWithRed:0.20 green:0.20 blue:0.20 alpha:1.0]];
    
    _highView.layer.cornerRadius = 5;
    [_highView setBackgroundColor:[UIColor colorWithRed:0.15 green:0.58 blue:1.00 alpha:1.0]];
    _normalView.layer.cornerRadius = 5;
    [_normalView setBackgroundColor:[UIColor colorWithRed:0.42 green:0.91 blue:0.46 alpha:1.0]];
    _lowView.layer.cornerRadius = 5;
    [_lowView setBackgroundColor:[UIColor colorWithRed:0.93 green:0.39 blue:0.25 alpha:1.0]];
}

- (IBAction)backClicked:(id)sender{
    
    [self.navigationController popViewControllerAnimated:NO];
    NSLog(@"back clicked");
}

#pragma mark - UITableviewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 2;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    return 66.0f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    static NSString *CellIdentifier = @"infoCell";
    infoCell *cell = [_mainTable dequeueReusableCellWithIdentifier:CellIdentifier];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.mainLabel.textAlignment = NSTextAlignmentCenter;
    
    NSString *titleString;
    
    if (indexPath.row == 0) {
        titleString = @"Send Feedback";
    }else{
        titleString = @"Disclaimer & Restore";
    }
    
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue-Thin" size:18.0f],
                                 NSForegroundColorAttributeName: [UIColor colorWithHex:@"ACACAC"]};//[UIColor colorWithHex:@"ACACAC"]};
    NSAttributedString *cellString = [[NSAttributedString alloc] initWithString:titleString attributes:attributes];
    
    cell.mainLabel.attributedText = cellString;
    
    return cell;
    
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [cell setSeparatorInset:UIEdgeInsetsZero];
    [cell setPreservesSuperviewLayoutMargins:NO];
    [cell setLayoutMargins:UIEdgeInsetsZero];
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.5f;
}


- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    
    view.tintColor = [UIColor colorWithRed:0.20 green:0.20 blue:0.20 alpha:1.0];
    
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0) {
        [self feedbackClicked];
    }else{
        [self performSegueWithIdentifier:@"disclaimerSegue" sender:self];
    }
}



#pragma mark - IBActions

- (IBAction)disclaimerClicked:(id)sender {
    [self performSegueWithIdentifier:@"disclaimerSegue" sender:self];
}

- (void)feedbackClicked {
    if ([MFMailComposeViewController canSendMail])
    {
        MFMailComposeViewController *mailer = [[MFMailComposeViewController alloc] init];
        
        NSArray *toRecipients = [NSArray arrayWithObjects:@"garrett@flowsapp.com", nil];
        [mailer setToRecipients:toRecipients];
        [mailer setSubject:@"Flows App Feedback"];
        mailer.mailComposeDelegate = self;
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            mailer.modalPresentationStyle = UIModalPresentationPageSheet;
        }
        
        [self presentViewController:mailer animated:YES completion:nil];
        
    } else {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" message:@"It seems as though your device is unable to send emails." preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okay = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
        [alert addAction:okay];
        [self presentViewController:alert animated:YES completion:nil];
    }
}


- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    [controller dismissViewControllerAnimated:YES completion:nil];
}


- (IBAction)cancelClicked:(id)sender {
    CATransition *transition = [CATransition animation];
    transition.duration = 0.5;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionPush;
    transition.subtype = kCATransitionFade;
    [self.navigationController.view.layer addAnimation:transition forKey:nil];
    [self.navigationController popViewControllerAnimated:NO];
}

@end
