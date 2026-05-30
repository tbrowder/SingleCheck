use Test;

my @modules = [
   "SingleCheck",
   "SingleCheck::Handlers",
   "SingleCheck::Utils",
   "SingleCheck::PayTo",
   "SingleCheck::Action",
   "SingleCheck::Data",
   "SingleCheck::Vars",
   "SingleCheck::Template",
   "SingleCheck::FontUtils",
];

plan @modules.elems;

for @modules -> $m {
    use-ok $m, "Module '$m' used okay";
}
