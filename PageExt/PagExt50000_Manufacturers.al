pageextension 50000 "Manufacturers Ext." extends Manufacturers
{
    layout
    {
        // Add changes to page layout here
        addlast(Control1)
        {
            field("Name RU"; "Name RU")
            {
                ApplicationArea = All;
            }
            field(Address; Address)
            {
                ApplicationArea = All;
            }
        }
    }
    local procedure MyProcedure()
    var
        myInt: Integer;
    begin

    end;
}
