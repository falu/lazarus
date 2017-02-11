{ calc_tr2d
  Copyright (C) 2017 Falu, https://github.com/falu
  This source is free software; you can redistribute it and/or modify it under
  the terms of the GNU General Public License as published by the Free
  Software Foundation; either version 2 of the License, or (at your option)
  any later version.
  This code is distributed in the hope that it will be useful, but WITHOUT ANY
  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
  FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
  details.
  A copy of the GNU General Public License is available on the World Wide Web
  at <http://www.gnu.org/copyleft/gpl.html>. You can also obtain it by writing
  to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston,
  MA 02111-1307, USA.
}
unit calc_tr2d;

{$mode objfpc}{$H+}

interface

type
  THelmertPar=record
    a1,b1,x0,y0:double;
  end;

  TAffinPar=record
    a1,b1,a2,b2,x0,y0:double;
  end;

  TKozosPont=record
    y1,x1,z1:double;
    y2,x2,z2:double;
    dy,dx,dz:double;
    bevont:boolean;
    suly:double;
  end;
  
  TAKozosPont=array of TKozosPont;

function Helmert(var k:TAKozosPont; var p:THelmertPar):boolean;
procedure Helmert_atszam(const x1,y1:double; const par: THelmertPar; var x2,y2:double);

function Affin(var k:TAKozosPont; var p:TAffinPar):boolean;
procedure Affin_atszam(const x1,y1:double; const par: TAffinPar; var x2,y2:double);

implementation

function Helmert(var k:TAKozosPont; var p:THelmertPar):boolean;
var
  i:longint;
  nkozos:longint; //közös pontok száma
  sulypont:tkozospont;
  sr:takozospont;
  r1,r2,r3:double;
begin

  result:=false;

  //sulypontúlypontok számítása mindkét rendszerben
  fillchar(sulypont,sizeof(sulypont),0);
  nkozos:=0;
  for i:=0 to length(k)-1 do if k[i].bevont then begin
    inc(nkozos);
    sulypont.x1:=sulypont.x1+k[i].x1;
    sulypont.y1:=sulypont.y1+k[i].y1;
    sulypont.x2:=sulypont.x2+k[i].x2;
    sulypont.y2:=sulypont.y2+k[i].y2;
  end;

  if nkozos<2 then exit;

  sulypont.x1:=sulypont.x1/nkozos;  sulypont.y1:=sulypont.y1/nkozos;
  sulypont.x2:=sulypont.x2/nkozos;  sulypont.y2:=sulypont.y2/nkozos;

  setlength(sr,length(k));

  //sulypontúlyponti koordináták, együtthatók számítása
  r1:=0;  r2:=0;  r3:=0;
  for i:=0 to length(k)-1 do if k[i].bevont then begin
    //1. rendszer
    sr[i].x1:= k[i].x1 - sulypont.x1;
    sr[i].y1:= k[i].y1 - sulypont.y1;
    //2. rendszer
    sr[i].x2:= k[i].x2 - sulypont.x2;
    sr[i].y2:= k[i].y2 - sulypont.y2;
    //együtthatók
    r1:= r1 + sr[i].x1*sr[i].x1 + sr[i].y1*sr[i].y1;
    r2:= r2 + sr[i].x1*sr[i].x2 + sr[i].y1*sr[i].y2;
    r3:= r3 + sr[i].x1*sr[i].y2 - sr[i].y1*sr[i].x2;
  end;

  if r1=0 then exit;

  //paraméterek
  p.a1:= r2/r1;
  p.b1:= r3/r1;
  p.x0:= sulypont.x2 - p.a1*sulypont.x1 + p.b1*sulypont.y1;
  p.y0:= sulypont.y2 - p.a1*sulypont.y1 - p.b1*sulypont.x1;

  { átszámítás
    x2 := x0 + a1 * x1 - b1 * y1
    y2 := y0 + b1 * x1 + a1 * y1
  }

  result:=true;

end;

procedure Helmert_atszam(const x1,y1:double; const par: THelmertPar; var x2,y2:double);
begin
  with par do begin
    x2:=x0 + a1*x1 - b1*y1;
    y2:=y0 + b1*x1 + a1*y1;
  end;
end;

function Affin(var k: TAKozosPont; var p: TAffinPar): boolean;
var
  i:longint;
  nkozos:longint; //közös pontok száma
  sulypont:tkozospont;
  sumsuly:double;
  sr:takozospont;
  r1,r2,r3,r4,r5,r6,r7:double;
begin
  result:=false;

  //sulypontúlypontok számítása mindkét rendszerben
  fillchar(sulypont,sizeof(sulypont),0);
  nkozos:=0;  sumsuly:=0;
  for i:=0 to length(k)-1 do if k[i].bevont then begin
    inc(nkozos);
    sumsuly:=sumsuly + k[i].suly;
    sulypont.x1:=sulypont.x1 + k[i].x1 * k[i].suly;
    sulypont.y1:=sulypont.y1 + k[i].y1 * k[i].suly;
    sulypont.x2:=sulypont.x2 + k[i].x2 * k[i].suly;
    sulypont.y2:=sulypont.y2 + k[i].y2 * k[i].suly;
  end;

  if sumsuly<=0 then exit;
  if nkozos<2 then exit;

  sulypont.x1:=sulypont.x1/sumsuly;  sulypont.y1:=sulypont.y1/sumsuly;
  sulypont.x2:=sulypont.x2/sumsuly;  sulypont.y2:=sulypont.y2/sumsuly;

  setlength(sr,length(k));

  //sulypontúlyponti koordináták, együtthatók számítása
  r1:=0;  r2:=0;  r3:=0; r4:=0; r5:=0; r6:=0; r7:=0;
  for i:=0 to length(k)-1 do if k[i].bevont then begin
    //1. rendszer
    sr[i].x1:= k[i].x1 - sulypont.x1;
    sr[i].y1:= k[i].y1 - sulypont.y1;
    //2. rendszer
    sr[i].x2:= k[i].x2 - sulypont.x2;
    sr[i].y2:= k[i].y2 - sulypont.y2;
    //együtthatók
    r1:=r1 + k[i].suly * sr[i].x1 * sr[i].x2;
    r2:=r2 + k[i].suly * sr[i].y1 * sr[i].y2;
    r3:=r3 + k[i].suly * sr[i].x1 * sr[i].y2;
    r4:=r4 + k[i].suly * sr[i].y1 * sr[i].x2;
    r5:=r5 + k[i].suly * sr[i].x1 * sr[i].x1;
    r6:=r6 + k[i].suly * sr[i].y1 * sr[i].y1;
    r7:=r7 + k[i].suly * sr[i].x1 * sr[i].y1;
  end;

  //paraméterek számítása

  with p do begin
    a1:=(r6*r1-r7*r4)/(r5*r6-r7*r7);
    b1:=(r6*r3-r7*r2)/(r5*r6-r7*r7);
    a2:=(r5*r4-r7*r1)/(r5*r6-r7*r7);
    b2:=(r5*r2-r7*r3)/(r5*r6-r7*r7);
    x0:=sulypont.x2 - a1*sulypont.x1 - a2*sulypont.y1;
    y0:=sulypont.y2 - b1*sulypont.x1 - b2*sulypont.y1;
  end;

  result:=true;

  {
  Átszámítás
  k2x = x0 + a1 * k1x + a2 * k2y
  k2y = y0 + b1 * k1x + b2 * k2y
  }
end;

procedure Affin_atszam(const x1,y1:double; const par: TAffinPar; var x2,y2:double);
begin
  with par do begin
    x2:=x0 + a1 * x1 + a2 * y1;
    y2:=y0 + b1 * x1 + b2 * y1;
  end;
end;

end.
