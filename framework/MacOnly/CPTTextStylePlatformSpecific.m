#import "CPTTextStylePlatformSpecific.h"

#import "CPTMutableTextStyle.h"
#import "CPTPlatformSpecificCategories.h"
#import "CPTPlatformSpecificFunctions.h"

@implementation CPTTextStyle(CPTPlatformSpecificTextStyleExtensions)

/** @property NSDictionary *attributes
 *  @brief A dictionary of standard text attributes suitable for formatting an NSAttributedString.
 *
 *  The dictionary will contain values for the following keys that represent the receiver's text style:
 *  - #NSFontAttributeName: The font used to draw text. If missing, no font information was specified.
 *  - #NSForegroundColorAttributeName: The color used to draw text. If missing, no color information was specified.
 *  - #NSParagraphStyleAttributeName: The text alignment and line break mode used to draw multi-line text.
 **/
@dynamic attributes;

#pragma mark -
#pragma mark Init/Dealloc

/** @brief Creates and returns a new CPTTextStyle instance initialized from a dictionary of text attributes.
 *
 *  The text style will be initalized with values associated with the following keys:
 *  - #NSFontAttributeName: Sets the @link CPTTextStyle::fontName fontName @endlink
 *  and @link CPTTextStyle::fontSize fontSize @endlink.
 *  - #NSForegroundColorAttributeName: Sets the @link CPTTextStyle::color color @endlink.
 *  - #NSParagraphStyleAttributeName: Sets the @link CPTTextStyle::textAlignment textAlignment @endlink and @link CPTTextStyle::lineBreakMode lineBreakMode @endlink.
 *
 *  Properties associated with missing keys will be inialized to their default values.
 *
 *  @param attributes A dictionary of standard text attributes.
 *  @return A new CPTTextStyle instance.
 **/
+(instancetype)textStyleWithAttributes:(NSDictionary *)attributes
{
    CPTMutableTextStyle *newStyle = [CPTMutableTextStyle textStyle];

    // Font
    NSFont *styleFont = attributes[NSFontAttributeName];

    if ( styleFont ) {
        newStyle.fontName = styleFont.fontName;
        newStyle.fontSize = styleFont.pointSize;
    }

    // Color
    NSColor *styleColor = attributes[NSForegroundColorAttributeName];
    if ( styleColor ) {
        // CGColor property is available in Mac OS 10.8 and later
        if ( [styleColor respondsToSelector:@selector(CGColor)] ) {
            newStyle.color = [CPTColor colorWithCGColor:styleColor.CGColor];
        }
        else {
            const NSInteger numberOfComponents = [styleColor numberOfComponents];

            CGFloat *components = calloc( (size_t)numberOfComponents, sizeof(CGFloat) );
            [styleColor getComponents:components];

            CGColorSpaceRef colorSpace = [[styleColor colorSpace] CGColorSpace];
            CGColorRef styleCGColor    = CGColorCreate(colorSpace, components);

            newStyle.color = [CPTColor colorWithCGColor:styleCGColor];

            CGColorRelease(styleCGColor);
            free(components);
        }
    }

    // Text alignment and line break mode
    NSParagraphStyle *paragraphStyle = attributes[NSParagraphStyleAttributeName];
    if ( paragraphStyle ) {
        newStyle.textAlignment = (CPTTextAlignment)paragraphStyle.alignment;
        newStyle.lineBreakMode = paragraphStyle.lineBreakMode;
    }

    return [newStyle copy];
}

#pragma mark -
#pragma mark Accessors

/// @cond

-(NSDictionary *)attributes
{
    NSMutableDictionary *myAttributes = [NSMutableDictionary dictionary];

    // Font
    NSFont *styleFont = [NSFont fontWithName:self.fontName size:self.fontSize];

    if ( styleFont ) {
        [myAttributes setValue:styleFont
                        forKey:NSFontAttributeName];
    }

    // Color
    NSColor *styleColor = self.color.nsColor;
    if ( styleColor ) {
        [myAttributes setValue:styleColor
                        forKey:NSForegroundColorAttributeName];
    }

    // Text alignment and line break mode
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.alignment     = (NSTextAlignment)self.textAlignment;
    paragraphStyle.lineBreakMode = self.lineBreakMode;

    [myAttributes setValue:paragraphStyle
                    forKey:NSParagraphStyleAttributeName];

    return [myAttributes copy];
}

/// @endcond

@end

#pragma mark -

@implementation CPTMutableTextStyle(CPTPlatformSpecificMutableTextStyleExtensions)

/// @cond

+(instancetype)textStyleWithAttributes:(NSDictionary *)attributes
{
    CPTMutableTextStyle *newStyle = [CPTMutableTextStyle textStyle];

    // Font
    NSFont *styleFont = attributes[NSFontAttributeName];

    if ( styleFont ) {
        newStyle.fontName = styleFont.fontName;
        newStyle.fontSize = styleFont.pointSize;
    }

    // Color
    NSColor *styleColor = attributes[NSForegroundColorAttributeName];
    if ( styleColor ) {
        // CGColor property is available in Mac OS 10.8 and later
        if ( [styleColor respondsToSelector:@selector(CGColor)] ) {
            newStyle.color = [CPTColor colorWithCGColor:styleColor.CGColor];
        }
        else {
            const NSInteger numberOfComponents = [styleColor numberOfComponents];

            CGFloat *components = calloc( (size_t)numberOfComponents, sizeof(CGFloat) );
            [styleColor getComponents:components];

            CGColorSpaceRef colorSpace = [[styleColor colorSpace] CGColorSpace];
            CGColorRef styleCGColor    = CGColorCreate(colorSpace, components);

            newStyle.color = [CPTColor colorWithCGColor:styleCGColor];

            CGColorRelease(styleCGColor);
            free(components);
        }
    }

    // Text alignment and line break mode
    NSParagraphStyle *paragraphStyle = attributes[NSParagraphStyleAttributeName];
    if ( paragraphStyle ) {
        newStyle.textAlignment = (CPTTextAlignment)paragraphStyle.alignment;
        newStyle.lineBreakMode = paragraphStyle.lineBreakMode;
    }

    return newStyle;
}

/// @endcond

@end

#pragma mark -

@implementation NSString(CPTTextStyleExtensions)

#pragma mark -
#pragma mark Layout

/** @brief Determines the size of text drawn with the given style.
 *  @param style The text style.
 *  @return The size of the text when drawn with the given style.
 **/
-(CGSize)sizeWithTextStyle:(CPTTextStyle *)style
{
    NSFont *theFont = [NSFont fontWithName:style.fontName size:style.fontSize];

    CGSize textSize;

    if ( theFont ) {
        NSDictionary *attributes = @{
            NSFontAttributeName: theFont
        };

        textSize = NSSizeToCGSize([self sizeWithAttributes:attributes]);
    }
    else {
        textSize = CGSizeZero;
    }

    return textSize;
}

#pragma mark -
#pragma mark Drawing

/** @brief Draws the text into the given graphics context using the given style.
 *  @param rect The bounding rectangle in which to draw the text.
 *  @param style The text style.
 *  @param context The graphics context to draw into.
 **/
-(void)drawInRect:(CGRect)rect withTextStyle:(CPTTextStyle *)style inContext:(CGContextRef)context
{
    if ( style.color == nil ) {
        return;
    }

    CGColorRef textColor = style.color.cgColor;

    CGContextSetStrokeColorWithColor(context, textColor);
    CGContextSetFillColorWithColor(context, textColor);

    CPTPushCGContext(context);
    NSFont *theFont = [NSFont fontWithName:style.fontName size:style.fontSize];
    if ( theFont ) {
        NSColor *foregroundColor                = style.color.nsColor;
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.alignment     = (NSTextAlignment)style.textAlignment;
        paragraphStyle.lineBreakMode = style.lineBreakMode;

        NSDictionary *attributes = @{
            NSFontAttributeName: theFont,
            NSForegroundColorAttributeName: foregroundColor,
            NSParagraphStyleAttributeName: paragraphStyle
        };
        [self drawWithRect:NSRectFromCGRect(rect)
                   options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading | NSStringDrawingTruncatesLastVisibleLine
                attributes:attributes];
    }
    CPTPopCGContext();
}

@end
