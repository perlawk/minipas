
program cosine;
var cos, x, n, term, eps, alt: real;
{compute the cosine of x to within tolerance eps}

begin
  x := 3.14159;
  eps := 0.0001;
  n := 1;
  cos := 1;
  term := 1;
  alt := -1;
  while term>eps do begin
    term := term*x*x/n/(n+1);
    cos := cos + alt*term;
    alt := -alt; 
    n := n + 2
    end
end.
