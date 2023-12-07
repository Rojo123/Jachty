import "dart:async";
import "package:mysql1/mysql1.dart";

var settings = ConnectionSettings(
  host: "cl14.netmark.pl",
  user: "praktyk1_userjacht",
  password: "w{nXL-TbiX1E",
  db: "praktyk1_wypozyczalniajachtow",
);

Future doQuery(String query) async{
  final con = await MySqlConnection.connect(settings);

  if(query.startsWith("SELECT ")){
    var result = await con.query(query);
    await con.close();
    return result;
  } else {
    await con.query(query);
    await con.close();
    return 0;
  }
}

//String query = "SELECT id, jacht, qrcode, status, gps, komentarz FROM wypozyczalnia";