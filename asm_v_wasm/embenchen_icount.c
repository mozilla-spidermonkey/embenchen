
/* This is a program to collect low-level perf info for JS shell runs.  Each
   test listed below is run twice, using the two shells listed on the command
   line (run with no args for help).  The tests are run using 'valgrind
   --tool=cachegrind'.  This collects counts of instructions, data reads, data
   writes, and other stuff we ignore.  After each run, 'cg_annotate' is used
   to dump the contents of the profile information as text, and from that, the
   count of the abovementioned events that originate from non-file-backed text
   pages is extracted.  The counts for all tests are collected, and at the end
   of the run, printed in a nice table.

   'cg_annotate' is a standard part of the Valgrind suite.

   We ignore all events in file-backed text pages.  Because all AOT compiled
   code lives in such pages, the effect is to extract only the counts for
   JIT-generated code, which is what we care about.

   To use:

   * edit below in "BEGIN configurable stuff" to specify
     - path to your valgrind executable (any version will do)
     - path to your cg_annotate executable
     - the set of tests to run

   * compile: gcc -g -Og -Wall -o embenchen_icount embenchen_icount.c -lpthread

   * then run.  This will tell you what command line args you need.  Choose
     those and run for real.

   There are many caveats:

   * All jobs will be run in parallel, because I was too lazy to write a
     proper thread scheduler.  This may come as a bit of a shock to the system
     if you don't have enough swap available.

   * Interrupting the runs doesn't work well.  You can eventually get rid of a
     run with repeated Control-Cs, but it will leave a bunch of files in /tmp.
     You can remove them with 'rm /tmp/embenchen_icount_cg*'.  Control-C
     handling could be improved without much effort.

   * Beware the percent-change columns, especially for writes (Dw).  Some of
     the tests do extremely few writes in JIT-generated code, so small changes
     in code generation can cause huge and misrepresentative values in this
     column.

   * The tests below are ordered roughly by decreasing numbers of hot blocks.
     That is, the first few tests spread their execution out over relative many
     blocks, and are probably more representative of real code.  Later entries
     are increasingly "narrow" in this sense.

   * The output from all runs is printed as it becomes available, along with
     some internal progress information.  It looks messy, but the final table
     is pretty.
*/

// BEGIN configurable stuff.

#define  VALGRIND     "/home/sewardj/Bin/vTRUNK"
#define  CG_ANNOTATE  "/home/sewardj/VgTRUNK/trunk/Inst/bin/cg_annotate"

// The test cases we want to run
const char* testCases[][2] = {
   // Fixed-length display name, for convenience
   //                  Actual test filename
#if 0
   // Use this for debugging this driver program.  It runs quickly.
   { "wasm_ifs      ", "wasm_ifs.js" },
#else
   // The real test collection, greatest spread of basic blocks first
   //{ "bz2           ", "bz2.js" }, // Not in Embenchen
   { "wasm_bullet   ", "wasm_bullet.js" },
   { "wasm_lua_bina ", "wasm_lua_binarytrees.c.js" },
   { "wasm_box2d    ", "wasm_box2d.js" },
   { "wasm_zlib.c   ", "wasm_zlib.c.js" },
   { "wasm_copy     ", "wasm_copy.js" },
   { "wasm_fannkuch ", "wasm_fannkuch.js" },
   { "raybench      ", "raybench.js" },
   { "fib           ", "fib.js" },
   // Basically they are hopelessly narrow after this point
   { "rust-fannkuch ", "rust-fannkuch.js" },
   //{ "simdbench_rayb", "simdbench_raybench.js" }, // Not in Embenchen
   //{ "simdbench_mand", "simdbench_mandel.js" }, // Not in Embenchen
   { "wasm_fasta    ", "wasm_fasta.js" },
   { "wasm_primes   ", "wasm_primes.js" },
   { "wasm_ifs      ", "wasm_ifs.js" },
   { "wasm_skinning ", "wasm_skinning.js" },
   { "wasm_correcti ", "wasm_corrections.js" },
   { "wasm_conditio ", "wasm_conditionals.js" },
   { "wasm_memops   ", "wasm_memops.js" },
#endif
};

// END configurable stuff.  No configurable stuff after this point.
// The shells to use, and the flags for them, are specified on the
// command line.  Run with no args for help.

#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <string.h>
#include <stdint.h>
#include <locale.h>
#include <pthread.h>

#define Bool unsigned char
#define False ((Bool)0)
#define True ((Bool)1)

typedef  unsigned long long int  ULong;

// There is one of these for each thread.
typedef 
   struct {
      const char* displayName;
      const char* testFileName;
      const char* shellPath;
      const char* shellArgs;
      // Ir,Dr,Dw in anonymous code
      ULong insns;
      ULong dreads;
      ULong dwrites;
   }
   WorkUnit;


WorkUnit* workUnits = NULL;

// For printing error messages
char* argv0 = NULL;

// Runs on WORKER THREADs
void parse_cgann_output_and_get_numbers(int wuNum,
                                        const char* filename,
                                        /*OUT*/ULong* numIr,
                                        /*OUT*/ULong* numDr,
                                        /*OUT*/ULong* numDw)
{
   *numIr = *numDr = *numDw = 0;

   FILE* f = fopen(filename, "r");
   assert(f);
   char* line = NULL;
   size_t nLine = 0;
   Bool alreadySeen = False;
   while (1) {
      ssize_t nRead = getline(&line, &nLine, f);
      if (nRead == -1) break;
      assert(nRead >= 0);
      if (strstr(line, "???:???") != NULL) {
         // No \n for the next printf, since `line` provides it anyway :-/
         printf("WU %2d: found: %s", wuNum, line);
         // We only expect to see one such line per file.
         assert(!alreadySeen);
         ULong nIr = 0, nDr = 0, nDw = 0;
         int r = sscanf(line,
                        "%'llu (%*f%%) %'llu (%*f%%) %'llu (%*f%%)  ???:???",
                        &nIr, &nDr, &nDw);
         printf("WU %2d: sscanf: got %d:  "
                "nIr = %llu, nDr = %llu, nDw = %llu\n",
                wuNum, r, nIr, nDr, nDw);
         // Some sanity checks.  If these fail, it's likely the line above
         // wasn't properly parsed.
         Bool plausible
            = (r == 3) // 3 fields converted
              // Any reasonable benchmark should run for at least 100k insns
              // in unlabelled code.
              && nIr >= 100 * 1000
              // Similar sanity checks for data read/write numbers.
              && nDr >= 20 * 1000
              && nDw >= 1 * 1000;
         if (!plausible) {
            fprintf(stderr,
                    "%s: found invalid '\?\?\?:\?\?\?' line, giving up:\n",
                    argv0);
            fprintf(stderr, "%s: %s\n", argv0, line);
            assert(0);
         }
         alreadySeen = True;
         *numIr = nIr;
         *numDr = nDr;
         *numDw = nDw;
      }
   }
   fclose(f);
   if (line) free(line);
}

// Runs on WORKER THREADs (this is the thread root fn)
void* run_wu(void* arg) {
   int wuNum = (int)(intptr_t)arg;
   WorkUnit* wu = &workUnits[wuNum];
   assert(wu->insns == 0 && wu->dreads == 0 && wu->dwrites == 0);

   char tmpFN1[64];
   char tmpFN2[64];
   memset(tmpFN1, 0, sizeof(tmpFN1));
   memset(tmpFN2, 0, sizeof(tmpFN2));

   sprintf(tmpFN1, "/tmp/embenchen_icount_cgout_tid%d_wu%d",
           getpid(), wuNum);
   sprintf(tmpFN2, "/tmp/embenchen_icount_cgann_tid%d_wu%d",
           getpid(), wuNum);

   // We want to run:
   //
   // VALGRIND -q --tool=cachegrind --cachegrind-out-file=<tmpFN1>
   //           <wu->shellPath> <wu->shellFlags>
   //           <wu->testFileName>
   //
   // CG_ANNOTATE --show=Ir,Dr,Dw <tmpFN1> &> <tmpFN2>
   //
   const size_t cmdLen = 5000;
   char* cmdCG = calloc(1, cmdLen);
   assert(cmdCG);
   snprintf(cmdCG, cmdLen-1,
            "%s -q --tool=cachegrind --cachegrind-out-file=%s %s %s %s",
            VALGRIND, tmpFN1, wu->shellPath, wu->shellArgs, wu->testFileName);

   char* cmdCA = calloc(1, cmdLen);
   assert(cmdCA);
   snprintf(cmdCA, cmdLen-1,
            "%s --show=Ir,Dr,Dw %s &> %s",
            CG_ANNOTATE, tmpFN1, tmpFN2);

   printf("WU %2d: running '%s --tool=cachegrind ...'\n", wuNum, VALGRIND);
   int r = system(cmdCG);
   if (r < 0) {
      fprintf(stderr, "%s: FAILED: %s\n", argv0, cmdCG);
      fprintf(stderr, "with r = %d\n", r);
      assert(0);
   }

   printf("WU %2d: running '%s ...'\n", wuNum, CG_ANNOTATE);
   r = system(cmdCA);
   if (r < 0) {
      fprintf(stderr, "%s: FAILED: %s\n", argv0, cmdCA);
      fprintf(stderr, "with r = %d\n", r);
      assert(0);
   }

   ULong nIr = 0, nDr = 0, nDw = 0;
   parse_cgann_output_and_get_numbers(wuNum, tmpFN2, &nIr, &nDr, &nDw);

   wu->insns = nIr;
   wu->dreads = nDr;
   wu->dwrites = nDw;

   r = unlink(tmpFN1); assert(r == 0);
   r = unlink(tmpFN2); assert(r == 0);

   free(cmdCG);
   free(cmdCA);

   return NULL;
}

// Helper
double deltaPercent(ULong n1, ULong n2) {
   double d1 = (double)n1;
   double d2 = (double)n2;
   return 100.0 * ((d2 - d1) / d1);
}

// Runs on MAIN THREAD
void summarise(const WorkUnit* wu1, const WorkUnit* wu2) {
   assert(wu1 != wu2);
   // Check these are for the same test case!
   assert(0 == strcmp(wu1->displayName, wu2->displayName));
   assert(0 == strcmp(wu1->testFileName, wu2->testFileName));
   // Check these are *not* for the same shell
   assert(0 != strcmp(wu1->shellPath, wu2->shellPath));

   const ULong M = 1000*1000;
   printf("%s: "
          "Ir: %'6lluM => %'6lluM (%+6.2f%%)  |  "
          "Dr: %'6lluM => %'6lluM (%+6.2f%%)  |  "
          "Dw: %'6lluM => %'6lluM (%+6.2f%%)\n",
          wu1->displayName,

          wu1->insns / M, wu2->insns / M,
          deltaPercent(wu1->insns, wu2->insns),

          wu1->dreads / M, wu2->dreads / M,
          deltaPercent(wu1->dreads, wu2->dreads),

          wu1->dwrites / M, wu2->dwrites / M,
          deltaPercent(wu1->dwrites, wu2->dwrites));
}

int numTestCases(void) {
   return sizeof(testCases) / sizeof(testCases[0]);
}

void usage(char* argv0) {
   fprintf(stderr,
           "usage: %s \\\n"
           "           /path/to/first/js/shell "
           "\"--args --for --first --shell\" \\\n"
           "           /path/to/second/js/shell "
           "\"--args --for --second --shell\"" "\n",
           argv0);
   exit(1);
}

Bool isExecutable(const char* path) {
   struct stat buf;
   memset(&buf, 0, sizeof(buf));
   int r = stat(path, &buf);
   if (r != 0) return False;   
   return S_ISREG(buf.st_mode) && ((buf.st_mode &  S_IXUSR) != 0);
}

// Runs on MAIN THREAD
int main(int argc, char** argv) {
   argv0 = argv[0];

   if (argc != 5) {
      usage(argv[0]);
   }

   if (!isExecutable(argv[1])) {
      fprintf(stderr, "%s: %s is not executable\n", argv[0], argv[1]);
      exit(1);
   }
   
   if (!isExecutable(argv[3])) {
      fprintf(stderr, "%s: %s is not executable\n", argv[0], argv[2]);
      exit(1);
   }

   // This is needed to ensure that the "'" (thousands-separator character)
   // in the sscanf call above, is properly parsed.
   char* res = setlocale(LC_ALL, "en_US");
   assert(res);
   
   // Prepare work units.  There are 2 work units for each test case.  By
   // convention, for test case number `i` we use work units `2 * i` and `2 * i
   // + 1`.
   const int numTests = numTestCases();
   const int numWUs = numTests * 2;

   // Prepare per-thread-info blocks
   workUnits = calloc(numWUs, sizeof(WorkUnit));
   assert(workUnits);
   for (int i = 0; i < numTests; i++) {
      WorkUnit* wu1 = &workUnits[2 * i + 0];
      WorkUnit* wu2 = &workUnits[2 * i + 1];
      wu1->displayName = testCases[i][0];
      wu2->displayName = testCases[i][0];
      wu1->testFileName = testCases[i][1];
      wu2->testFileName = testCases[i][1];
      wu1->shellPath = argv[1];
      wu1->shellArgs = argv[2];
      wu2->shellPath = argv[3];
      wu2->shellArgs = argv[4];
   }

   // Show the work units
   for (int i = 0; i < numWUs; i++) {
      WorkUnit* wu = &workUnits[i];
      printf("WU %2d: (for %s): %s %s %s\n",
             i, wu->displayName,
             wu->shellPath, wu->shellArgs, wu->testFileName);
   }

   // Run all work units in parallel (this is exceedingly stupid)
   pthread_t* threads = calloc(sizeof(pthread_t), numWUs);

   for (int i = 0; i < numWUs; i++) {
      int r = pthread_create(&threads[i], NULL, run_wu, (void*)(intptr_t)i);
      assert(r == 0);
   }

   for (int i = 0; i < numWUs; i++) {
      void* retval = NULL;
      int r = pthread_join(threads[i], &retval);
      assert(r == 0);
      assert(retval == NULL);
   }

   // We're done.  Summarise the results, nicely.

   printf("\n");
   printf("==== Instructions, data reads and data writes in non-file-back"
          "ed mappings ================================================\n");
   printf("==\n");
   printf("SHELL 1:  %s\n", argv[1]);
   printf("ARGS  1:  %s\n", argv[2]);
   printf("SHELL 2:  %s\n", argv[3]);
   printf("ARGS  2:  %s\n", argv[4]);
   printf("\n");
   if (0) {
      printf("--TEST_NAME--   --TEST_PATH--\n");
      for (int i = 0; i < numTestCases(); i++) {
         printf("%s  %s\n", testCases[i][0], testCases[i][1]);
      }
      printf("\n");
   }
   printf("--TEST_NAME--   "
          "----------INSTRUCTIONS----------     "
          "--------------READS-------------     "
          "-------------WRITES-------------\n");
   for (int i = 0; i < numTests; i++) {
      summarise(&workUnits[2 * i + 0], &workUnits[2 * i + 1]);
   }

   // Calculate and print the average deltas
   double totDeltaIr = 0.0, totDeltaDr = 0.0, totDeltaDw = 0.0;
   for (int i = 0; i < numTests; i++) {
      totDeltaIr += deltaPercent(workUnits[2 * i + 0].insns,
                                 workUnits[2 * i + 1].insns);
      totDeltaDr += deltaPercent(workUnits[2 * i + 0].dreads,
                                 workUnits[2 * i + 1].dreads);
      totDeltaDw += deltaPercent(workUnits[2 * i + 0].dwrites,
                                 workUnits[2 * i + 1].dwrites);
   }
   totDeltaIr /= (double)numTests;
   totDeltaDr /= (double)numTests;
   totDeltaDw /= (double)numTests;
   printf("                                       ---------"
          "                            ---------"
          "                            ---------\n");
   printf("(AVG DELTA)                            (%+6.2f%%)"
          "                            (%+6.2f%%)"
          "                            (%+6.2f%%)\n",
          totDeltaIr, totDeltaDr, totDeltaDw);
   printf("==\n");
   printf("============================================================="
          "=============================================================\n");
   printf("\n");

   free(threads);
   threads = NULL;

   free(workUnits);
   workUnits = NULL;

   return 0;
}
