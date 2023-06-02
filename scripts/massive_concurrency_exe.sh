#!/bin/bash
for i in {1..20}
do
    echo $(mix test test/massive_concurrency_test.exs)
done
