codeunit 50006 "IC Extended"
{
    trigger OnRun()
    begin

    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Release Sales Document", 'OnAfterReleaseSalesDoc', '', false, false)]
    local procedure CreatePOFromSO(var SalesHeader: Record "Sales Header")
    var
        _PurchHeader: Record "Purchase Header";
    begin
        with _PurchHeader do begin
            SetCurrentKey("IC Document No.");
            SetRange("IC Document No.", SalesHeader."No.");
            if IsEmpty then
                CreateICPurchaseOrder(SalesHeader);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Copy Document Mgt.", 'OnAfterTransfldsFromSalesToPurchLine', '', false, false)]
    local procedure Update(var FromSalesLine: Record "Sales Line"; var ToPurchaseLine: Record "Purchase Line")
    begin
        with ToPurchaseLine do
            Validate("Direct Unit Cost", FromSalesLine."Unit Price");
    end;

    local procedure CreateICPurchaseOrder(fromSalesHeader: Record "Sales Header")
    var
        fromSalesLine: Record "Sales Line";
        toPurchHeader: Record "Purchase Header";
        ICVendorNo: Code[20];
    begin
        ICVendorNo := GetICVendor(CompanyName);
        if ICVendorNo = '' then exit;

        with fromSalesLine do begin
            SetRange("Document Type", fromSalesHeader."Document Type");
            SetRange("Document No.", fromSalesHeader."No.");
            SetRange(Type, Type::Item);
            SetFilter(Quantity, '<>%1', 0);
            if fromSalesLine.IsEmpty then exit;
        end;

        // Copy Sales Order to Purchase Order
        CopySalesOrder2PurchaseOrder(ICVendorNo, fromSalesHeader, toPurchHeader);

        // Send Intercompany Purchase Order
        SendIntercompanyPurchaseOrder(toPurchHeader);
    end;

    procedure SendIntercompanyPurchaseOrder(var toPurchHeader: Record "Purchase Header")
    begin
        if ApprovalsMgmt.PrePostApprovalCheckPurch(toPurchHeader) then
            ICInOutboxMgt.SendPurchDoc(toPurchHeader, false);
    end;

    procedure CopySalesOrder2PurchaseOrder(ICVendorNo: Code[20]; fromSalesHeader: Record "Sales Header"; var toPurchHeader: Record "Purchase Header")
    begin
        toPurchHeader."Document Type" := toPurchHeader."Document Type"::Order;
        toPurchHeader."IC Document No." := fromSalesHeader."No.";
        CLEAR(CopyDocumentMgt);
        CopyDocumentMgt.SetProperties(TRUE, FALSE, FALSE, FALSE, TRUE, FALSE, FALSE);
        CopyDocumentMgt.CopyFromSalesToPurchDoc(ICVendorNo, fromSalesHeader, toPurchHeader);
    end;

    local procedure GetICVendor(ICPartner: Text[100]): Code[20]
    var
        _Vendor: Record Vendor;
    begin
        with _Vendor do begin
            if ICPartner <> CompanyName then
                ChangeCompany(ICPartner);
            SetCurrentKey("IC Partner Code");
            SetFilter("IC Partner Code", '<>%1', '');
            if FindFirst() then
                exit("No.")
            else
                exit('');
        end;
    end;

    var
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
        ICInOutboxMgt: Codeunit ICInboxOutboxMgt;
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
}