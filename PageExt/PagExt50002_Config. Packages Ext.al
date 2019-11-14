pageextension 50002 "Config. Packages Ext." extends "Config. Package Subform"
{
    layout
    {
    }
    actions
    {
        // Add changes to page actions here
        addafter(ImportFromExcel)
        {
            // action(ExportBigDataExcel)
            // {
            //     ApplicationArea = All;
            //     Caption = 'Export Item Descr. to Excel';
            //     Image = ExportToExcel;

            //     trigger OnAction()
            //     begin
            //         ExportBigDataExcel;
            //     end;
            // }
            action(ImportBigDataExcel)
            {
                ApplicationArea = All;
                Caption = 'Import Item Descr. from Excel';
                Image = ImportExcel;

                trigger OnAction()
                begin
                    ImportBigDataExcel;
                end;
            }
            action(Export2JSON)
            {
                ApplicationArea = All;
                Caption = 'Export2JSON';
                Image = ExchProdBOMItem;

                trigger OnAction()
                begin
                    Export2JSON;
                end;
            }
        }
    }
    var // ExcelBigDataMigrator: Codeunit "Excel BigData Migrator";
    procedure ImportBigDataExcel()
    var
        ItemDescrManagement: Codeunit "Item Descr. Management";
    begin
        // CurrPage.SETSELECTIONFILTER(ConfigPackageTable);
        // ExcelBigDataMigrator.SetSelectedTables(ConfigPackageTable);
        // ExcelBigDataMigrator.ImportExcelFromSelectedPackage("Package Code");
        ItemDescrManagement.ImportExcelSheet;
    end;

    procedure Export2JSON()
    var
        ConfigPackageTable: Record "Config. Package Table";
        ItemDescrManagement: Codeunit "Item Descr. Management";
    begin
        CurrPage.SetSelectionFilter(ConfigPackageTable);
        ItemDescrManagement.Export2JSON(ConfigPackageTable);
    end;

    local procedure SelectionConfirmMessage(ConfigPackageTable: Record "Config. Package Table"): Text
    var
        myInt: Integer;
    begin
        // IF ConfigPackageTable.COUNT <> 1 THEN
        //     EXIT(STRSUBSTNO(MultipleTablesSelectedQst, ConfigPackageTable.COUNT));
        // EXIT(SingleTableSelectedQst);
    end;

    var
        MultipleTablesSelectedQst: TextConst ENU = '%1 tables have been selected. Do you want to continue?';
        SingleTableSelectedQst: TextConst ENU = 'One table has been selected. Do you want to continue?';
}
