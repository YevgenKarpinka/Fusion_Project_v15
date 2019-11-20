pageextension 50009 "Item List Ext." extends "Item List"
{
    layout
    {
        // Add changes to page layout here
        addafter(Type)
        {
            field("Expiration Inventory"; "Expiration Inventory")
            {
                ApplicationArea = All;
            }
        }
    }

    actions
    {
        // Add changes to page actions here
    }
}