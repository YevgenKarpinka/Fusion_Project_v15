report 50002 "Sales Order Fusion"
{
    CaptionML = ENU = 'Sales Order Fusion', RUS = 'Заказ продажи';
    DefaultLayout = RDLC;
    RDLCLayout = 'Sales Order Fusion.rdl';
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;

    dataset
    {
        dataitem(SalesHeader; "Sales Header")
        {
            RequestFilterFields = "No.", "Sell-to Customer No.";
            DataItemTableView = where("Document Type" = Const(Order));

            column(CompanyName; CompanyInfo.Name + CompanyInfo."Name 2") { }
            column(CompanyAdress; CompanyInfo.Address + CompanyInfo."Address 2") { }
            column(CompanyCity; CompanyInfo.City + ', ' + CompanyInfo.County + ' ' + CompanyInfo."Post Code") { }
            column(CompanyPhone; CompanyInfo."Phone No.") { }
            column(CompanyFax; CompanyInfo."Phone No. 2") { }
            column(Bill_to_Name; "Bill-to Name" + "Bill-to Name 2") { }
            column(Bill_to_Address; "Bill-to Address" + "Bill-to Address 2") { }
            column(Bill_to_City; "Bill-to City" + ' ' + "Bill-to County" + ' ' + "Bill-to Post Code") { }
            column(TotalAmount; "Amount Including VAT") { }
            dataitem(SaleLine; "Sales Line")
            {
                DataItemTableView = sorting("Document Type", "Document No.", "Line No.");
                DataItemLink = "Document No." = field("No.");

                column(Quantity; Quantity)
                {
                    DecimalPlaces = 0 : 0;
                }
                column(Description; Description) { }
                column(Unit_Price; "Unit Price")
                {
                    DecimalPlaces = 2 : 2;
                }
                column(AmountIncludingVAT; "Amount Including VAT")
                {
                    DecimalPlaces = 2 : 2;
                }

                trigger OnAfterGetRecord()
                begin
                end;

            }
        }
    }

    requestpage
    {
        layout { }
        actions { }
    }

    trigger OnInitReport()
    begin
        CompanyInfo.Get();
    end;

    trigger OnPreReport()
    begin

    end;

    var
        CompanyInfo: Record "Company Information";
}