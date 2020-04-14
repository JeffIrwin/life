      ! TODO:
      !
      !   - exit code for checking in test.sh
      !
      !   - optional number of pixels per cell
      !
      !   - IO is very slow.  There is no point optimizing the grid
      !     update until better IO is found.
      !       * binary pbm output, c.f. mandelbrotZoom
      !
      !   - for seeds with escaped gliders and many generations, IO may
      !     not be the limiting factor
      !
      !   - avoid using min and max; instead, write special cases for
      !     bottom-most, top-most, left-most, and right-most
      !     rows/columns
      !
      !   - use logic such that if a point and its neighbors do not
      !     change, stop checking it
      !
      !   - parallelism does not seem to help for small grids

      module lifemod

      implicit none

      contains

!=======================================================================

      subroutine writerle(filename, g)

      character :: filename*(*)

      integer :: ifile, il, iu, jl, ju, ni, nj, j0, i, j, i0, length
      integer, parameter :: lenmax = 69

      logical*1 :: g0
      logical*1, allocatable :: g(:,:)

      il = lbound(g, 1)
      iu = ubound(g, 1)
      jl = lbound(g, 2)
      ju = ubound(g, 2)

      ni = iu - il + 1
      nj = ju - jl + 1

      open(newunit = ifile, file = filename)

      write(ifile, '(a)') '# file '//trim(filename)//' generated by '
     &                  //'writerle'
      write(ifile, '(a, i0, a, i0)') 'x = ', nj, ', y = ', ni

      length = 0
      i = il
      do while (i <= iu)
        i0 = i
        do while (.not. any(g(i, :)))
          i = i + 1
          if (i == iu) exit
        end do

        if (i - i0 > 0) then
          length = length + ceiling(log10(dble(i - i0 + 1)))
          if (length + 1 > lenmax) then
            length = ceiling(log10(dble(i - i0 + 1)))
          write(ifile, *)
          end if
          write(ifile, '(i0)', advance = 'no') i - i0 + 1

          length = length + 1
          if (length > lenmax) then
            length = 1
            write(ifile, *)
          end if
          write(ifile, '(a)', advance = 'no') '$'

        else if (i > il) then
          length = length + 1
          if (length > lenmax) then
            length = 1
            write(ifile, *)
          end if
          write(ifile, '(a)', advance = 'no') '$'
        end if

        j = jl
        do while (j < ju)
          g0 = g(i, j)
          j0 = j
          do while (g(i, j + 1) .eqv. g0)
            j = j + 1
            if (j == ju) exit
          end do
          j = j + 1
          if (j - j0 > 1) then
            length = length + ceiling(log10(dble(j - j0)))
            if (length + 1 > lenmax) then
              length = ceiling(log10(dble(j - j0)))
              write(ifile, *)
            end if
            write(ifile, '(i0)', advance = 'no') j - j0
          end if
          if (g0) then
            length = length + 1
            if (length > lenmax) then
              length = 1
              write(ifile, *)
            end if
            write(ifile, '(a)', advance = 'no') 'o'
          else
            length = length + 1
            if (length > lenmax) then
              length = 1
              write(ifile, *)
            end if
            write(ifile, '(a)', advance = 'no') 'b'
          end if
        end do

        i = i + 1
      end do

      length = length + 1
      if (length > lenmax) then
        length = 1
        write(ifile, *)
      end if
      write(ifile, '(a)', advance = 'no') '!'

      close(ifile)

      end subroutine writerle

!=======================================================================

      function readrle(filename)

      ! Read seed grid in a run-length encoded format

      character :: c, filename*(*), line*256, numchars(10)

      integer :: ifile, ni, nj, i, j, k, k0, k1, runcount

      logical*1, allocatable :: readrle(:,:)

      numchars = [ '0', '1', '2', '3', '4', '5', '6', '7', '8', '9' ]

      open(newunit = ifile, file = filename)

      read(ifile, *) c
      do while (c == '#')
        read(ifile, *) c
      end do
      !print *, 'c = ', c

      backspace(ifile)
      do while (c /= '=')
        read(ifile, '(a)', advance = 'no') c
        !print *, 'c = ', c
      end do

      read(ifile, *) nj
      !print *, 'nj = ', nj

      backspace(ifile)
      do i = 1, 2
        read(ifile, '(a)', advance = 'no') c
        do while (c /= '=')
          read(ifile, '(a)', advance = 'no') c
          !print *, 'c = ', c
        end do
      end do

      read(ifile, *) ni
      !print *, 'ni = ', ni

      allocate(readrle(ni, nj))
      readrle(:,:) = .false.

      i = 1
      j = 1

      do while (c /= '!')
        read(ifile, '(a)') line
        !do k = 1, len_trim(line)
        k = 0
        do while (k < len_trim(line))
          k = k + 1

          c = line(k: k)
          !print *, 'c = ', c

          if (any(numchars == c)) then
            k0 = k
            k = k + 1
            c = line(k: k)
            do while (any(numchars == c))
              k = k + 1
              c = line(k: k)
            end do
            k1 = k - 1
            !print *, 'runcount = ', line(k0: k1)
            read(line(k0: k1), *) runcount
            !print *, 'runcount = ', runcount
            !print *, 'i, j = ', i, j
            !print *, 'c = ', c
            
            if (c == 'b') then
              readrle(i, j: j + runcount - 1) = .false.
              j = j + runcount
            else if (c == 'o') then
              readrle(i, j: j + runcount - 1) = .true.
              j = j + runcount
            else if (c == '$') then
              i = i + runcount
              j = 1
            else
              write(*,*)
              write(*,*) 'Error reading RLE file.'
              write(*,*) 'Bad character '//c//' after runcount '
     &                   //line(k0: k1)
              write(*,*)
              stop
            end if
          else if (c == 'b') then
            readrle(i, j) = .false.
            j = j + 1
          else if (c == 'o') then
            readrle(i, j) = .true.
            j = j + 1
          else if (c == '$') then
            i = i + 1
            j = 1
          else if (c == '!') then
            ! End of file.  Do nothing.
          else
            write(*,*)
            write(*,*) 'Error reading RLE file.'
            write(*,*) 'Bad character '//c//'.'
            write(*,*)
            stop
          end if
        end do
      end do

      close(ifile)

      end function readrle

!=======================================================================

      function readcells(filename)

      character :: filename*(*), c, line*8096

      integer :: ifile, ni, nj, i, j, io

      logical*1, allocatable :: readcells(:,:)

      ! Read seed grid in the format of a matrix of 0's and 1's.
      open(newunit = ifile, file = filename)

      read(ifile, *) c
      do while (c == '!')
        read(ifile, *) c
      end do
      backspace(ifile)

      ! Find size
      read(ifile, '(a)') line
      nj = len_trim(line)

      if (nj == 8096) then
        write(*,*)
        write(*,*) 'Error'
        write(*,*) 'Too many columns in '//trim(filename)
        write(*,*) 'Increase line length and re-compile.'
        write(*,*)
        stop
      end if

      rewind(ifile)
      read(ifile, *) c
      do while (c == '!')
        read(ifile, *) c
      end do
      backspace(ifile)

      io = 0
      ni = 0
      do while (io == 0)
        read(ifile, '(a)', iostat = io) c
        ni = ni + 1
      end do
      ni = ni - 1

      rewind(ifile)
      read(ifile, *) c
      do while (c == '!')
        read(ifile, *) c
      end do
      backspace(ifile)

      allocate(readcells(1: ni, 1: nj))
      do i = 1, ni
        do j = 1, nj

          if (j < nj) then
            read(ifile, '(a)', advance = 'no') c
          else
            read(ifile, '(a)', advance = 'yes') c
          end if

          if (c == '.') then
            readcells(i, j) = .false.
          else if (c == 'O') then
            readcells(i, j) = .true.
          else
            write(*,*)
            write(*,*) 'Error reading input file '//trim(filename)
            write(*,*) 'Input grid must consist of .''s and O''s'
            write(*,*)
            stop
          end if
        end do
      end do
      close(ifile)

      end function readcells

!=======================================================================

      function readtxt(filename)

      ! Read seed grid in the format of a matrix of 0's and 1's with the
      ! matrix size in the header.

      character :: filename*(*)

      integer :: ifile, ni, nj, i, j
      integer, allocatable :: kalloc(:)

      logical*1, allocatable :: readtxt(:,:)

      open(newunit = ifile, file = filename)
      read(ifile, *) ni
      read(ifile, *) nj
      allocate(readtxt (1: ni, 1: nj))
      allocate(kalloc(nj))
      do i = 1, ni
        read(ifile, *) kalloc(:)
        do j = 1, nj
          if (kalloc(j) == 0) then
            readtxt(i, j) = .false.
          else if (kalloc(j) == 1) then
            readtxt(i, j) = .true.
          else
            write(*,*)
            write(*,*) 'Error reading input file '//trim(filename)
            write(*,*) 'Input grid must consist of 0''s and 1''s'
            write(*,*)
            stop
          end if
        end do
      end do
      close(ifile)

      end function readtxt

!=======================================================================

      ! filename      name of the file to be written to
      !
      ! g             logical grid of live/dead cells
      !
      ! n1            lower bound of image dimension 1
      !
      ! n2            lower bound of image dimension 2
      !
      ! n3            upper bound of image dimension 1
      !
      ! n4            upper bound of image dimension 2
      !
      ! tran          if true, transpose the grid
      !
      ! invert        if true, invert the colors (make live cells black)

      ! Could also add fliplr and flipud options.

      subroutine writepbm(filename, g, n1, n2, n3, n4, tran, invert)

      character :: c, filename*(*), c1, c0

      integer :: i, j, ifile, il, iu, jl, ju, n1, n2, n3, n4, n13, n24,
     &           tmp, n1l, n2l, n3l, n4l

      logical :: tran, invert
      logical*1, allocatable :: g(:,:)

      ! FFMPEG requires dimensions in multiples of 2.
      n13 = (n3 - n1)
      n24 = (n4 - n2)
      if (mod(n13, 2) == 0) n3 = n3 + 1
      if (mod(n24, 2) == 0) n4 = n4 + 1

      il = lbound(g, 1)
      iu = ubound(g, 1)
      jl = lbound(g, 2)
      ju = ubound(g, 2)

      if (tran) then

        n1l = n2
        n2l = n1
        n3l = n4
        n4l = n3

        tmp = il
        il = jl
        jl = tmp

        tmp = iu
        iu = ju
        ju = tmp

      else

        n1l = n1
        n2l = n2
        n3l = n3
        n4l = n4

      end if

      open(newunit = ifile, file = filename)
      write(ifile, '(a)') 'P1'
      write(ifile, '(i0, a, i0)') n4 - n2 + 1, ' ', n3 - n1 + 1

      if (invert) then
        c0 = '1'
        c1 = '0'
      else
        c0 = '0'
        c1 = '1'
      end if

      ! Top padding
      do i = n1, il - 1
        do j = n2, n4
          write(ifile, '(a)', advance = 'no') c1//' '
        end do
        write(ifile,*)
      end do

      do i = max(il, n1), min(iu, n3)

        ! Left padding
        do j = n2, jl - 1
          write(ifile, '(a)', advance = 'no') c1//' '
        end do

        ! Main body
        do j = max(jl, n2), min(ju, n4)

          c = c1
          if (tran) then
            if (g(j, i)) c = c0
          else
            if (g(i, j)) c = c0
          end if
          write(ifile, '(a)', advance = 'no') c//' '

        end do

        ! Right padding
        do j = ju + 1, n4
          write(ifile, '(a)', advance = 'no') c1//' '
        end do
        write(ifile,*)
      end do

      ! Bottom padding
      do i = iu + 1, n3
        do j = n2, n4
          write(ifile, '(a)', advance = 'no') c1//' '
        end do
        write(ifile,*)
      end do

      close(ifile)

      end subroutine writepbm

!=======================================================================

      ! Could also add a transpose option.

      subroutine writegrid(filename, g, fliplr, flipud)

      character :: c, filename*(*)

      integer :: i, j, ifile, il, iu, jl, ju, tmp, is, js

      logical :: flipud, fliplr
      logical*1, allocatable :: g(:,:)

      il = lbound(g, 1)
      iu = ubound(g, 1)
      jl = lbound(g, 2)
      ju = ubound(g, 2)
      is = 1
      js = 1

      if (fliplr) then
        tmp = jl
        jl = ju
        ju = tmp
        js = -1
      end if
      if (flipud) then
        tmp = il
        il = iu
        iu = tmp
        is = -1
      end if

      open(newunit = ifile, file = filename)
      write(ifile, '(i0)') iu - il + 1
      write(ifile, '(i0)') ju - jl + 1
      do i = il, iu, is
        do j = jl, ju, js
          c = '0'
          if (g(i, j)) c = '1'
          write(ifile, '(a)', advance = 'no') c//' '
        end do
        write(ifile,*)
      end do
      close(ifile)

      end subroutine writegrid

!=======================================================================

      subroutine printgrid(g)

      character :: c

      integer :: i, j, jl, ju
      logical*1, allocatable :: g(:,:)

      jl = lbound(g, 2)
      ju = ubound(g, 2)

      do i = lbound(g, 1), ubound(g, 1)
        do j = jl, ju
          c = ' '
          if (g(i, j)) c = 'o'
          write(*, '(a)', advance = 'no') c//' '
        end do
        write(*,*)
      end do

      end subroutine printgrid

!=======================================================================

      subroutine nextgen(filepre, n1, n2, n3, n4, writeout, dead, tran,
     &           invert, g0, g, n, niminmin, njminmin, nimaxmax,
     &           njmaxmax, frames)

      character :: cn*256, filepre*256, fres*256, frames*256

      integer :: i, j, n, nimin, njmin, nimax, njmax, nimin0,
     &           nimax0, njmin0, njmax0, nbrs, niminmin, nimaxmax,
     &           njminmin, njmaxmax, n1, n2, n3, n4

      logical :: writeout, dead, tran, invert
      logical*1, allocatable :: g(:,:), g0(:,:)

      ! Trim or extend the grid.
      nimin0 = lbound(g0, 1)
      njmin0 = lbound(g0, 2)
      nimax0 = ubound(g0, 1)
      njmax0 = ubound(g0, 2)

      nimin = nimin0
      njmin = njmin0
      nimax = nimax0
      njmax = njmax0

      if (count(g0(:,:)) == 0) then
        write(*,*)
        write(*,*) 'The pattern has disappeared.'
        write(*,*)
        dead = .true.
      end if

      do while (all(.not. g0(nimin, :)))
        nimin = nimin + 1
      end do
      do while (all(.not. g0(:, njmin)))
        njmin = njmin + 1
      end do
      do while (all(.not. g0(nimax, :)))
        nimax = nimax - 1
      end do
      do while (all(.not. g0(:, njmax)))
        njmax = njmax - 1
      end do
      nimin = nimin - 1
      njmin = njmin - 1
      nimax = nimax + 1
      njmax = njmax + 1

      deallocate(g)
      allocate(g(nimin: nimax, njmin: njmax))

      niminmin = min(niminmin, nimin)
      njminmin = min(njminmin, njmin)
      nimaxmax = max(nimaxmax, nimax)
      njmaxmax = max(njmaxmax, njmax)

!$OMP parallel private(i,j,nbrs) shared(njmin,njmax,nimin,nimax,g,g0)
!$OMP do
      do j = njmin, njmax
        do i = nimin, nimax

          nbrs = count(g0(max(i - 1, nimin0): min(i + 1, nimax0),
     &                    max(j - 1, njmin0): min(j + 1, njmax0)))

          if (nimin0 <= i .and. i <= nimax0 .and.
     &        njmin0 <= j .and. j <= njmax0) then
            if (g0(i, j)) then
              if (nbrs < 3) then
                g(i, j) = .false.
              else if ( nbrs < 5) then
                g(i, j) = .true.
              else
                g(i, j) = .false.
              end if
            else if (nbrs == 3) then
              g(i, j) = .true.
            else
              g(i, j) = .false.
            end if
          else if (nbrs == 3) then
            g(i, j) = .true.
          else
            g(i, j) = .false.
          end if
        end do
      end do
!$OMP end do
!$OMP end parallel

      !deallocate(g0)
      !allocate(g0(nimin: nimax, njmin: njmax))
      !g0 = g

      if (writeout) then
        write(cn, '(i0)') n
        fres = trim(frames)//'/'//trim(filepre)//'_'//trim(cn)//'.pbm'
        call writepbm(fres, g, n1, n2, n3, n4, tran, invert)
      end if

      end subroutine nextgen

!=======================================================================

      end module lifemod

      !! Test writegrid
      !filename = 'meth946.rle'
      !g = readrle(filename)
      !call writegrid('test_write.txt', g, .true., .false.)

      !! Place two gosper glider guns facing each other.
      !g1 = readtxt('gosper.txt')
      !g2 = readtxt('gosper_fliplr_flipud.txt')
      !allocate(g(90, 134))
      !g(:,:) = .false.
      !g(1:9, 1:36) = g1
      !g(82: 90, 99: 134) = g2
      !call writegrid('gosper_shootout.txt', g, .false., .false.)
      !stop

!=======================================================================

      program life

      use lifemod

      implicit none

      character :: filename*256, cn*256, ans, filepre*256, ext*32,
     &             fres*256, frames*256

      integer :: i, j, nmax, n, niminmin, nimaxmax, njminmin, njmaxmax,
     &           n1, n2, n3, n4, ifile

      logical :: writeout, dead, fexist, tran, invert
      logical*1, allocatable :: g(:,:), g0(:,:), g1(:,:), g2(:,:)

      write(*,*)
      write(*,*) 'Enter seed grid file name:'
      read(*,*) filename

      inquire(file = filename, exist = fexist)
      if (.not. fexist) then
        write(*,*)
        write(*,*) 'Error'
        write(*,*) 'Could not find file '//trim(filename)
        write(*,*)
        stop
      end if

      j = len_trim(filename)
      do while (filename(j: j) /= '.')
        j = j - 1
      end do
      filepre = filename(1: j - 1)
      ext = filename(j + 1: len_trim(filename))

      if (ext == 'rle') then
        g = readrle(filename)
      else if (ext== 'txt') then
        g = readtxt(filename)
      else if (ext == 'cells') then
        g = readcells(filename)
      else
        write(*,*)
        write(*,*) 'Error'
        write(*,*) 'Unrecognized file format '//trim(filename)
        write(*,*)
        stop
      end if

      write(*,*)
      write(*,*) 'Enter maximum number of ticks:'
      read(*,*) nmax

      write(*,*)
      write(*,*) 'Write results to file? (y/n)'
      read(*,*) ans

      writeout = .false.
      if (ans == 'y') writeout = .true.

      if (writeout) then

        write(*,*)
        write(*,*) 'Enter grid bounds for output'
        write(*,*) '(lower 1, lower 2, upper 1, upper 2):'
        read(*,*) n1, n2, n3, n4

        if (n1 >= n3 .or. n2 >= n4) then
          write(*,*)
          write(*,*) 'Error'
          write(*,*) 'Bounding box must have positive area'
          write(*,*)
          stop
        end if

        frames = 'frames'
        inquire(file = trim(frames), exist = fexist)
        if (.not. fexist) call system('mkdir '//trim(frames))

        write(cn, '(i0)') 0
        fres = trim(frames)//'/'//trim(filepre)//'_'//trim(cn)//'.pbm'

        inquire(file = fres, exist = fexist)
        if (fexist) then
          call system('rm '//trim(frames)//'/'//trim(filepre)//'_*')
        end if

        write(*,*)
        write(*,*) 'Transpose video frames? (y/n)'
        read(*,*) ans
        tran = .false.
        if (ans == 'y') tran = .true.

        write(*,*)
        write(*,*) 'Invert video colors? (y/n)'
        read(*,*) ans
        invert = .false.
        if (ans == 'y') invert = .true.

        call writepbm(fres, g, n1, n2, n3, n4, tran, invert)

      end if

      !call writegrid('cata.txt', g, .false., .false.)
      !call writegrid('catacryst.txt', g, .false., .false.)
      !call writerle('cata.rle', g)
      !stop

      niminmin = lbound(g, 1)
      njminmin = lbound(g, 2)
      nimaxmax = ubound(g, 1)
      njmaxmax = ubound(g, 2)

      allocate(g0(niminmin: nimaxmax, njminmin: njmaxmax))
      g0 = g

      !!  Convert input to rle for convenience
      !call writerle(trim(filepre)//'_rle.rle', g)

      ! Time loop
      dead = .false.
      n = 0
      do while (n < nmax .and. .not. dead)

        ! Switch roles of g and g0 every other frame

        n = n + 1
        if (writeout) write(*,*) 'Frame ', n
        call nextgen(filepre, n1, n2, n3, n4, writeout, dead, tran,
     &           invert, g0, g, n, niminmin, njminmin, nimaxmax,
     &           njmaxmax, frames)

        n = n + 1
        if (writeout) write(*,*) 'Frame ', n
        call nextgen(filepre, n1, n2, n3, n4, writeout, dead, tran,
     &           invert, g, g0, n, niminmin, njminmin, nimaxmax,
     &           njmaxmax, frames)

      end do

      !open(newunit = ifile, file = trim(filepre)//'_cols.txt')
      !write(ifile, '(a)') '# column, number of live cells'
      !do j = lbound(g, 2), ubound(g, 2)
      !  write(ifile, *) j, count(g(:, j))
      !end do
      !close(ifile)

      !open(newunit = ifile, file = trim(filepre)//'_rows.txt')
      !write(ifile, '(a)') '# row, number of live cells'
      !do i = lbound(g, 1), ubound(g, 1)
      !  write(ifile, *) i, count(g(i, :))
      !end do
      !close(ifile)

      write(*,*)
      write(*,*) 'number of generations = ', n
      write(*,*)
      write(*,*) 'lower bounds = ', niminmin, njminmin
      write(*,*) 'upper bounds = ', nimaxmax, njmaxmax

      end program life

