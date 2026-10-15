import LightningDatatable from "lightning/datatable";
import odaCellTableTemplate from "./odaCellTableTemplate.html";

export default class OdaDatatable extends LightningDatatable {
  static customTypes = {
    odaCellTable: {
      template: odaCellTableTemplate,
      standardCellLayout: true,
      typeAttributes: ["props", "clickable", "postfix"]
    }
  };
}