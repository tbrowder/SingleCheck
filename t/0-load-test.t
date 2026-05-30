use Test;

my @modules = [
   "SampleCheck",
   "SampleCheck::Handlers",
   "SampleCheck::Utils",
   "SampleCheck::PayTo",
   "SampleCheck::Action",
   "SampleCheck::Data",
   "SampleCheck::Vars",
   "SampleCheck::Template",
   "SampleCheck::FontUtils",
];

plan @modules.elems;

for @modules -> $m {
    use-ok $m, "Module '$m' used okay";
}
