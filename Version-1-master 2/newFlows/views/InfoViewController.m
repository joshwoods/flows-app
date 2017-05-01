//
//  AddStationViewController.m
//
//  Copyright © 2015 Matt Riddoch. All rights reserved.
//

#import "InfoViewController.h"
#import "UIColor+Hexadecimal.h"
#import <MessageUI/MessageUI.h>
#import <QuartzCore/QuartzCore.h>

@interface InfoViewController () <MFMailComposeViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UIButton *feedbackButton;
@property (weak, nonatomic) IBOutlet UIView *feedbackSeparator;
@property (weak, nonatomic) IBOutlet UIButton *disclaimerButton;

@end

@implementation InfoViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self applyDesign];
}

- (void)applyDesign
{
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new]
                                                  forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = [UIImage new];
    self.navigationController.navigationBar.translucent = YES;
    
    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"HeaderLogo"]];
    
    UIFont *font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:18.0f];
    UIColor *color = [UIColor colorWithHex:@"ACACAC"];
    [self.feedbackButton.titleLabel setFont:font];
    [self.feedbackButton setTitleColor:color forState:UIControlStateNormal];
    [self.feedbackButton.titleLabel setText:@"Send Feedback"];
    [self.disclaimerButton.titleLabel setFont:font];
    [self.disclaimerButton setTitleColor:color forState:UIControlStateNormal];
    [self.disclaimerButton.titleLabel setText:@"Disclaimer & Restore"];
    
    if ([MFMailComposeViewController canSendMail] == NO) {
        self.feedbackButton.hidden = YES;
        self.feedbackSeparator.hidden = YES;
    }
}

#pragma mark - IBActions

- (IBAction)backClicked:(id)sender
{
    [self.navigationController popViewControllerAnimated:NO];
}

- (IBAction)feedbackTapped:(id)sender
{
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
        // This should never be reached as we are hiding the button if there is no capability of sending an email. However, we will leave it here as a fallback.
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" message:@"It seems as though your device is unable to send emails." preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okay = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
        [alert addAction:okay];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (IBAction)disclaimerTapped:(id)sender
{
    [self performSegueWithIdentifier:@"disclaimerSegue" sender:self];
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    [controller dismissViewControllerAnimated:YES completion:nil];
}


- (IBAction)cancelClicked:(id)sender
{
    CATransition *transition = [CATransition animation];
    transition.duration = 0.5;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionPush;
    transition.subtype = kCATransitionFade;
    [self.navigationController.view.layer addAnimation:transition forKey:nil];
    [self.navigationController popViewControllerAnimated:NO];
}

@end
