import "dart:async";
import "package:mysql1/mysql1.dart";
import "package:yacht_rental/config.dart";

var settings = ConnectionSettings(
  host: dbHost,
  user: dbUser,
  password: dbPass,
  db: db,
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