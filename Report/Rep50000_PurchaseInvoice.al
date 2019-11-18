report 50000 "Customer List"
{
    CaptionML = ENU = 'Purchase Invoice', RUS = 'Purchase Invoice';
    RDLCLayout = 'Purchase Invoice.rdl';

    dataset
    {
        dataitem(PurchaseHeader; "Purchase Header")
        {
            // RequestFilterFields = "No.", "Search Name", "Customer Posting Group";
            column(VendorName; "Buy-from Vendor Name") { }
            column(VendorName_2; "Buy-from Vendor Name 2") { }
            column(CompanyName; COMPANYNAME)
            {
                CaptionML = ENU = 'Company Name', RUS = 'Имя Компании';
            }
            column(DocumentNo; "No.") { }
            column(Posting_Date; "Posting Date") { }
            column(PH_TableCaption_PH_Filter; TABLECAPTION + ': ' + PH_Filter) { }
            column(PH_Filter; PH_Filter) { }
            column(VendAddr1; VendAddr[1]) { }
            column(VendAddr2; VendAddr[2]) { }
            column(VendAddr3; VendAddr[3]) { }
            column(VendAddr4; VendAddr[4]) { }
            column(VendAddr5; VendAddr[5]) { }
            column(VendAddr6; VendAddr[6]) { }
            column(VendAddr7; VendAddr[7]) { }
            column(VendAddr8; VendAddr[8]) { }
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
                FormatAddressFields(PurchaseHeader);
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

    trigger OnInitReport()
    begin
        CompanyInfo.Get();
    end;

    trigger OnPreReport()
    var
        CaptionMgt: Codeunit "Caption Mgt.";
    begin
        PH_Filter := CaptionMgt.GetRecordFiltersWithCaptionsPurchaseHeader(PurchaseHeader);
    end;

    local procedure FormatAddressFields(VAR PurchaseHeader: Record "Purchase Header")
    begin
        FormatAddr.GetCompanyAddr(PurchaseHeader."Responsibility Center", RespCenter, CompanyInfo, CompanyAddr);
        FormatAddr.PurchHeaderPayTo(VendAddr, PurchaseHeader);
    end;

    var
        Vend: Record Vendor;
        CompanyInfo: Record "Company Information";
        RespCenter: Record "Responsibility Center";
        FormatAddr: Codeunit "Format Address";
        CaptionMgt: Codeunit "Caption Mgt.";
        PH_Filter: Text;
        BuyFromAddr: array[8] of Text[100];
        VendAddr: array[8] of Text[100];
        ShipToAddr: array[8] of Text[100];
        CompanyAddr: array[8] of Text[100];
        PositionNo: Integer;
}