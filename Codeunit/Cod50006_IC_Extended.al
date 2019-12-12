codeunit 50006 "IC Extended"
{
    trigger OnRun()
    begin

    end;

    [EventSubscriber(ObjectType::Codeunit, 414, 'OnAfterReleaseSalesDoc', '', false, false)]
    local procedure CreatePOFromSO(var SalesHeader: Record "Sales Header")
    var

    begin

        CopyICDocuments(SalesHeader);
    end;

    local procedure CopyICDocuments(fromSalesHeader: Record "Sales Header")
    var
        _ICPartner: Record "IC Partner";
        toSalesHeader: Record "Sales Header";
        toSalesLine: Record "Sales Line";
        fromSalesLine: Record "Sales Line";
        toPurchHeader: Record "Purchase Header";
        toPurchLine: Record "Purchase Line";
        ICVendorNo: Code[20];
        ICCustomerNo: Code[20];
        ICPartner: Text[250];
    begin
        with fromSalesLine do begin
            SetRange("Document Type", fromSalesHeader."Document Type");
            SetRange("Document No.", fromSalesHeader."No.");
            SetRange(Type, Type::Item);
            SetFilter(Quantity, '<>%1', 0);
            if fromSalesLine.IsEmpty then exit;
        end;

        toSalesLine.ChangeCompany(ICPartner);
        GetInterCompany(ICPartner);

        with toPurchHeader do begin
            SetCurrentKey("IC Document No.");
            SetRange("IC Document No.", fromSalesHeader."No.");
            if not FindFirst() then begin
                // create Purchase Header
                Init();
                "Document Type" := "Document Type"::Order;
                Insert();
                ICVendorNo := GetICVendor(CompanyName);
                Validate("Buy-from Vendor No.", ICVendorNo);
                "IC Document No." := fromSalesHeader."No.";
                Modify();
            end else begin
                // before create deleting Purchase Line
                toPurchLine.SetRange("Document Type", toPurchLine."Document Type"::Order);
                toPurchLine.SetRange("Document No.", toPurchHeader."No.");
                toPurchLine.DeleteAll();
            end;
        end;

        // create Purchase Line
        with toSalesLine do begin

        end;

        with toSalesHeader do begin
            SetCurrentKey("IC Document No.");
            SetRange("IC Document No.", fromSalesHeader."No.");
            if not FindFirst() then begin
                _ICPartner.ChangeCompany(ICPartner);
                // create Sales Header into IC Partner 
                ChangeCompany(ICPartner);
                Init();
                "Document Type" := "Document Type"::Order;
                Insert();
                ICCustomerNo := GetICCustomer(ICPartner);
                Validate("Sell-to Customer No.", ICCustomerNo);
                "IC Document No." := fromSalesHeader."No.";
                Modify();
            end else begin
                // before create deleting Sales Line
                toSalesLine.SetRange("Document Type", toPurchLine."Document Type"::Order);
                toSalesLine.SetRange("Document No.", toPurchHeader."No.");
                toSalesLine.DeleteAll();
            end;
        end;

        // create Sales Line into IC Partner
        with toSalesLine do begin

        end;
    end;

    local procedure GetICCustomer(ICPartner: Text[100]): Code[20]
    var
        _Customer: Record Customer;
    begin
        with _Customer do begin
            if ICPartner <> CompanyName then
                ChangeCompany(ICPartner);
            SetCurrentKey("IC Partner Code");
            SetFilter("IC Partner Code", '<>%1', '');
            FindFirst();
            exit("No.");
        end;
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
            FindFirst();
            exit("No.");
        end;
    end;

    local procedure GetInterCompany(var ICPartner: Text[250])
    var
        _ICPartner: Record "IC Partner";
    begin
        _ICPartner.FindFirst();
        ICPartner := _ICPartner."Inbox Details";
    end;
}