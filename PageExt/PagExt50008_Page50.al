pageextension 50008 "Purchase Order Ext." extends "Purchase Order"
{
    layout
    {
        // Add changes to page layout here
    }

    actions
    {
        // Add changes to page actions here
        addafter("&Print")
        {
            action("Print Invoice")
            {
                ApplicationArea = All;
                Image = PurchaseInvoice;
                trigger OnAction()
                begin
                    Report.Run(Report::"Purchase Invoice", false, true, Rec);
                end;
            }
        }
    }
}