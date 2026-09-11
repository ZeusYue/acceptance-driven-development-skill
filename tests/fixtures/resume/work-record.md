# Count-label fix

The user requested the singular/plural fix (AC-3). The last session ended after
running `python -m unittest -v`: one and export passed; plural failed. No external
dependency was identified. The implementation still always returns "item".

Next: correct the plural branch and verify count labels and the existing export.
