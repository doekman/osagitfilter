BUILD=${CURDIR}/build
INCLUDE=osagetlang.sh osagitfilter.sh setup.sh README.md LICENSE

build: $(INCLUDE)
	@[ -d $(BUILD) ] || mkdir -p $(BUILD)
	zip $(BUILD)/osagitfilter.zip $^
	tar -cvzf $(BUILD)/osagitfilter.tar.gz $^

clean:
	@rm -Rf build

test:
	${CURDIR}/test.sh

.PHONY: clean test
