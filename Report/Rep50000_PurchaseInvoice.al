report 50000 "Customer List"
{
    CaptionML = ENU = 'Purchase Invoice', RUS = 'Purchase Invoice';
    RDLCLayout = 'Purchase Invoice.rdl';

    dataset
    {
        dataitem(PurchaseHeader; "Purchase Header")
        {
            // RequestFilterFields = "No.", "Search Name", "Customer Posting Group";
            column(Vendor_Name; "Buy-from Vendor Name") { }
            column(Vendor_Name_2; "Buy-from Vendor Name 2") { }
            column(CompanyName; COMPANYNAME)
            {
                CaptionML = ENU = 'Company Name', RUS = 'Имя Компании';
            }
            column(CurrReport_PAGENO; "No.") { }
            column(PH_TableCaption_PH_Filter; TABLECAPTION + ': ' + PH_Filter) { }
            column(PH_Filter; PH_Filter) { }
            // column(Cust_No; "No.") { }
            // column(Cust_Customer_Posting_Group; "Customer Posting Group") { }
            // column(Cust_Customer_Disc_Group; "Customer Disc. Group") { }
            // column(Cust_Invoice_Disc_Code; "Invoice Disc. Code") { }
            // column(Cust_Customer_Price_Group; "Customer Price Group") { }
            // column(Cust_Fin_Charge_Terms_Code; "Fin. Charge Terms Code") { }
            // column(Cust_Payment_Terms_Code; "Payment Terms Code") { }
            // column(Cust_Salesperson_Code; "Salesperson Code") { }
            // column(Cust_Currency_Code; "Currency Code") { }
            // column(Cust_Credit_Limit_LCY; "Credit Limit (LCY)")
            // {
            //     DecimalPlaces = 0 : 0;
            // }
            // column(Cust_Balance_LCY; "Balance (LCY)") { }
            column(VendAddr1; VendAddr[1]) { }
            column(VendAddr2; VendAddr[2]) { }
            column(VendAddr3; VendAddr[3]) { }
            column(VendAddr4; VendAddr[4]) { }
            column(VendAddr5; VendAddr[5]) { }
            column(VendAddr6; VendAddr[6]) { }
            column(VendAddr7; VendAddr[7]) { }
            column(VendAddr8; VendAddr[8]) { }
            // column(CustAddr2; CustAddr[2]) { }
            // column(CustAddr3; CustAddr[3]) { }
            // column(CustAddr4; CustAddr[4]) { }
            // column(CustAddr5; CustAddr[5]) { }
            // column(Cust_Contact; Contact) { }
            // column(Cust_Phone_No; "Phone No.") { }
            // column(CustAddr6; CustAddr[6]) { }
            // column(CustAddr7; CustAddr[7]) { }
            // column(Cust_ListCaption; Customer_ListCaptionLbl) { }
            // column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl) { }
            // column(Cust_NoCaption; FIELDCAPTION("No.")) { }
            // column(Cust_Customer_Posting_GroupCaption; Customer_Customer_Posting_GroupCaptionLbl) { }
            // column(Cust_Customer_Disc_GroupCaption; Customer_Customer_Disc_GroupCaptionLbl) { }
            // column(Cust_Invoice_Disc_CodeCaption; Customer_Invoice_Disc_CodeCaptionLbl) { }
            // column(Cust_Customer_Price_GroupCaption; Customer_Customer_Price_GroupCaptionLbl) { }
            // column(Cust_Fin_Charge_Terms_CodeCaption; FIELDCAPTION("Fin. Charge Terms Code")) { }
            // column(Cust_Payment_Terms_CodeCaption; Customer_Payment_Terms_CodeCaptionLbl) { }
            // column(Cust_Salesperson_CodeCaption; FIELDCAPTION("Salesperson Code")) { }
            // column(Cust_Currency_CodeCaption; Customer_Currency_CodeCaptionLbl) { }
            // column(Cust_Credit_Limit_LCYCaption; FIELDCAPTION("Credit Limit (LCY)")) { }
            // column(Cust_Balance_LCYCaption; FIELDCAPTION("Balance (LCY)")) { }
            // column(Cust_ContactCaption; FIELDCAPTION(Contact)) { }
            // column(Cust_Phone_NoCaption; FIELDCAPTION("Phone No.")) { }
            // column(Total_LCY_Caption; Total_LCY_CaptionLbl) { }

            dataitem("Purchase Line"; "Purchase Line")
            {
                DataItemTableView = SORTING("Document Type", "Document No.", "Line No.");
                DataItemLink = "Document Type" = FIELD("Document Type"), "Document No." = FIELD("No.");

                column(PositionNo; PositionNo)
                {
                }
                column(Description; Description)
                {
                }
                column(Quantity; Quantity)
                {
                    DecimalPlaces = 0 : 0;
                }
                column(UnitPriceLCY; "Unit Price (LCY)")
                {
                    DecimalPlaces = 0 : 2;
                }
                column(AmountIncludingVAT; "Amount Including VAT")
                {
                    DecimalPlaces = 0 : 2;
                }
                column(GrossWeight; "Gross Weight")
                {
                    DecimalPlaces = 0 : 0;
                }
                column(FDA_Value; CaptionMgt.GetItemAttributeValue('FDA Code', "No."))
                {
                }
                column(HTS_Value; CaptionMgt.GetItemAttributeValue('HTS Code', "No."))
                {
                }

            }

            trigger OnAfterGetRecord();
            begin
                with Vend do begin
                    Get("Buy-from Vendor No.");
                    FormatAddr.FormatAddr(VendAddr, Name, "Name 2", Contact, Address, "Address 2",
                                             City, "Post Code", County, "Country/Region Code");
                end;
            end;


        }

    }

    requestpage
    {
        SaveValues = true;

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
        LabelName = 'Label Text', Comment = 'Foo', MaxLength = 999, Locked = true;
    }

    trigger OnPreReport()
    var
        CaptionMgt: Codeunit "Caption Mgt.";
    begin
        PH_Filter := CaptionMgt.GetRecordFiltersWithCaptionsPurchaseHeader(PurchaseHeader);
    end;

    var
        Vend: Record Vendor;
        FormatAddr: Codeunit "Format Address";
        CaptionMgt: Codeunit "Caption Mgt.";
        PH_Filter: Text;
        VendAddr: array[8] of Text[100];
        PositionNo: Integer;
}