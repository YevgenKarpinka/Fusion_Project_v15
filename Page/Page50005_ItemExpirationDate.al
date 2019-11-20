page 50005 "Item Expiration Date List"
{
    PageType = Worksheet;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "Item Ledger Entry";
    SourceTableView = sorting("Item No.", Open, "Variant Code", Positive, "Location Code", "Posting Date", "Expiration Date", "Lot No.", "Serial No.")
                        where(Open = const(true), "Remaining Quantity" = filter(> 0));

    layout
    {
        area(Content)
        {
            group(GroupName)
            {
                field("Terms And Conditions"; codeTermsAndConditions)
                {
                    ApplicationArea = All;
                    TableRelation = "Terms And Conditions";
                    CaptionML = ENU = 'Terms And Conditions', RUS = 'Условия';

                    trigger OnValidate()
                    var
                        _TermsAndConditions: Record "Terms And Conditions";
                    begin
                        if _TermsAndConditions.Get(codeTermsAndConditions) and (nameTermsAndConditions <> _TermsAndConditions.Description) then begin
                            nameTermsAndConditions := _TermsAndConditions.Description;
                            CurrPage.Update(false);
                        end;
                    end;
                }
                field("Terms And Conditions Name"; nameTermsAndConditions)
                {
                    ApplicationArea = All;
                    CaptionML = ENU = 'Terms And Conditions Name', RUS = 'Условия Описание';
                    Editable = false;
                }
            }
            repeater(RepeaterName)
            {
                Editable = false;
                field("Item No."; "Item No.")
                {
                    ApplicationArea = All;

                }
                field("Remaining Quantity"; "Remaining Quantity")
                {
                    ApplicationArea = All;

                }
                field("Expiration Date"; "Expiration Date")
                {
                    ApplicationArea = All;

                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = All;

                }
                field("Variant Code"; "Variant Code")
                {
                    ApplicationArea = All;

                }
                field("Lot No."; "Lot No.")
                {
                    ApplicationArea = All;

                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = All;

                }
            }
        }
    }

    actions
    {

    }

    var
        codeTermsAndConditions: Text[10];
        nameTermsAndConditions: Text[10];
}