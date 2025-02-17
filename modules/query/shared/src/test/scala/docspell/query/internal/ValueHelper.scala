package docspell.query.internal

import docspell.query.Date
import docspell.query.ItemQuery._
import java.time.Period

trait ValueHelper {

  def ld(year: Int, m: Int, d: Int): Date.DateLiteral =
    Date(year, m, d).fold(throw _, identity)

  def ldPlus(year: Int, m: Int, d: Int, p: Period): Date.Calc =
    Date.Calc(ld(year, m, d), Date.CalcDirection.Plus, p)

  def ldMinus(year: Int, m: Int, d: Int, p: Period): Date.Calc =
    Date.Calc(ld(year, m, d), Date.CalcDirection.Minus, p)

  def stringExpr(op: Operator, name: Attr.StringAttr, value: String): Expr.SimpleExpr =
    Expr.SimpleExpr(op, Property.StringProperty(name, value))

  def dateExpr(op: Operator, name: Attr.DateAttr, value: Date): Expr.SimpleExpr =
    Expr.SimpleExpr(op, Property.DateProperty(name, value))

}
