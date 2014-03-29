
#import "MMMWhatsAppActivity.h"

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag
#endif

#define MMM_WHATSAPP_URL @"whatsapp://"
#define MMM_WHATSAPP_IMAGEFILENAME @"wa.wai"
#define MMM_WHATSAPP_IMAGEUTI @"net.whatsapp.image"


@interface MMMWhatsAppActivity()
@property (nonatomic,strong) NSString *text;
@property (nonatomic,strong) UIImage *image;
@property (nonatomic,strong) UIDocumentInteractionController *documentInteractionController;
@end

@implementation MMMWhatsAppActivity

#pragma mark - UIActivity

- (NSString *)activityType{
    return @"io.marcanton.whatsapp";
}

- (NSString *)activityTitle
{
    return @"WhatsApp";
}

+ (UIActivityCategory)activityCategory{
    return UIActivityCategoryShare;
}

- (UIImage *)activityImage
{
    UIImage *image=[UIImage imageNamed:@"MMMWhatsAppActivityIcon.png"];
    return image;
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems
{
    if([self whatsappInstalled]){
        for (id activityItem in activityItems)
        {
            if([activityItem isKindOfClass:[NSString class]]){
                return YES;
            } else if([activityItem isKindOfClass:[UIImage class]]){
                return YES;
            }
        }
        
    }
    return NO;
}

- (void)prepareWithActivityItems:(NSArray *)activityItems
{
    for (id activityItem in activityItems)
    {
        if([activityItem isKindOfClass:[NSString class]]){
            self.text=(NSString*)activityItem;
        }
        if([activityItem isKindOfClass:[UIImage class]]){
            self.image=(UIImage*)activityItem;
        }
    }
}

-(void)performActivity{
    
    if(self.image){
        [self openWhatsAppWithImage:self.image];
    } else if(self.text){
        [self openWhatsAppWithText:self.text];
    } else {
        [self activityDidFinish:NO]; // no recognized item, so signal that we're finished without success
    }
    
}

#pragma mark - Whatsapp

// cfr: http://www.whatsapp.com/faq/en/iphone/23559013

-(BOOL)whatsappInstalled{
    return [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:MMM_WHATSAPP_URL]];
}


-(void)openWhatsAppWithText:(NSString*)text{
    
    BOOL success=NO;
    text=[self stringByURLEncodingString:text];
    NSString *url=[NSString stringWithFormat:@"%@send?text=%@",MMM_WHATSAPP_URL,text];
    success=[[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
    
    // signal that we're finished
    [self activityDidFinish:success];
    
}

- (void)openWhatsAppWithImage:(UIImage*)image
{
    
    // check input validity..
    if(image&&[image isKindOfClass:[UIImage class]]){
        
        // create a filepath in our temporary directory, with .wai extensions (to trigger whatsapp)
        NSString *filepath=[NSTemporaryDirectory() stringByAppendingPathComponent:MMM_WHATSAPP_IMAGEFILENAME];
        NSURL *fileURL = [NSURL fileURLWithPath:filepath];
        
        // save image to path..
        if([UIImagePNGRepresentation(image) writeToFile:filepath atomically:YES]){
            
            // setup a document interaction controller with our file ..
            UIDocumentInteractionController *dic = [self setupControllerWithURL:fileURL
                                                                  usingDelegate:self];
            self.documentInteractionController=dic;
            dic.UTI = MMM_WHATSAPP_IMAGEUTI;
            dic.name = MMM_WHATSAPP_IMAGEFILENAME;
            if(self.text){
                dic.annotation=@{@"message":self.text,@"text":self.text};
            }
            
            // present menu with whatsapp icon
            UIView *view=[self topmostView];
            [dic presentOpenInMenuFromRect:view.bounds inView:view animated:YES];
            
            // exit; we're not calling activityDidFinish here, but later in documentInteractionControllerDidDismissOpenInMenu.
            return;
        }
    }
    
    // signal that we're finished
    [self activityDidFinish:NO];
    
}

- (void)documentInteractionControllerDidDismissOpenInMenu:(UIDocumentInteractionController *)controller{
    // signal that we're finished
    [self activityDidFinish:YES];
}

#pragma mark - Helpers

- (UIDocumentInteractionController *) setupControllerWithURL: (NSURL*) fileURL
                                               usingDelegate: (id <UIDocumentInteractionControllerDelegate>) interactionDelegate {
    
    UIDocumentInteractionController *interactionController =
    [UIDocumentInteractionController interactionControllerWithURL: fileURL];
    interactionController.delegate = interactionDelegate;
    
    return interactionController;
}

- (NSString *)stringByURLEncodingString:(NSString *)string
{
    CFStringRef urlEncodedString = CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)string, NULL,
                                                                           (CFStringRef)@"!*'();:@&=+$,/?%#[]", kCFStringEncodingUTF8);
    return CFBridgingRelease(urlEncodedString);
}

-(UIView*)topmostView{
    UIView *ret;
    ret=[[[[UIApplication sharedApplication] keyWindow] subviews] lastObject];
    if(!ret)ret=[[UIApplication sharedApplication] keyWindow];
    return ret;
}

@end
